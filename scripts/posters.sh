#!/bin/bash
set -x

# Downloads GitHub discussions as JSON + screenshot
# Run as bash script.sh owner repo
# Example: bash script.sh omigroup gltf-extensions

# Try loading the GITHUB_TOKEN from the .env file
#if [ -f .env ]; then
#    source .env
#fi

# Check if the GITHUB_TOKEN is still empty
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set. Please provide your GitHub personal access token." >&2
    # You can choose to exit or continue the script here as per your requirements
    # exit 1
fi

# Check if package dependencies are installed
packages=("capture-website" "jq" "pup")

for package in "${packages[@]}"; do
    if ! command -v "$package" &> /dev/null; then
        echo "$package is not installed. Installing now..."
        case "$package" in
            "capture-website")
                if ! npm install --global capture-website-cli; then
                    echo "Error: Failed to install capture-website-cli" >&2
                    exit 1
                fi
                ;;
            "jq")
                if ! sudo apt-get install jq -y; then
                    echo "Error: Failed to install jq" >&2
                    exit 1
                fi
                ;;
            "pup")
                if ! pip install pup; then
                    echo "Error: Failed to install pup" >&2
                    exit 1
                fi
                ;;
        esac
    fi
done


# assign command-line arguments to variables
if [ $# -ne 3 ]; then
    echo "This script archives GitHub Discussions" >&2
    echo "Usage: $0 <owner> <repo> <number of discussions>" >&2
    exit 1
fi

owner="$1"
repo="$2"
num="$3"

# Define the GraphQL query
QUERY_ALL=$(cat <<EOF
{
  "query": "query {
    repository(owner: \"$owner\", name: \"$repo\") {
      discussions(first: 12, orderBy: { field: CREATED_AT, direction: DESC }) {
        totalCount
        nodes {
          id
          category { name }
          upvoteCount
          updatedAt
          createdAt
          number
          title
          body
          author { login }
          comments(first: 30) {
            nodes {
              id
              author { login }
              body
            }
          }
          labels(first: 30) {
            nodes {
              id
              name
              color
              description
            }
          }
        }
      }
    }
  }"
}
EOF
)

# Write the GraphQL query to a file
echo "Writing the GraphQL query to a file"
if ! echo "$QUERY_ALL" > numbers.graphql; then
    echo "Error: Failed to write GraphQL query to file" >&2
    exit 1
fi

# Get a list of the past X amount of URLs
echo "Getting a list of URLs from past discussions"
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" -X POST -d @numbers.graphql "https://api.github.com/graphql" > "$owner"/"$owner"_"$repo".json

# Extract discussion numbers using jq
cat "$owner"/"$owner"_"$repo".json | jq -r '.data.repository.discussions.nodes[].number' | sort -n > numbers.txt

# Remove old files if there are any
if [ "$(ls -A "$repo"/)" ]; then
  if ! rm "$repo"/* 2>/dev/null; then
    echo "Failed to clean up old files" >&2
  fi
else
  echo "No files to clean up"
fi


i="$num"
# loop through each line in the numbers.txt file
while read -r number
do
  # capture the website as a JPEG image
  echo "capturing website"
  if ! capture-website "https://github.com/$owner/$repo/discussions/$number" --type=jpeg --quality=0.5 --full-page --element=".discussion" --scale-factor=1 --output=body_"$number".jpg --overwrite; then
      echo "Error: Failed to capture website for discussion $number" >&2
      continue
  fi


  # get the width of the body image using ImageMagick
  if ! width=$(identify -format "%w" body_"$number".jpg 2>/dev/null); then
    echo "Failed to get width of image body_$number.jpg" >&2
    continue
  fi

  # get the title of the discussion using curl and pup
  if ! title=$(curl -s "https://github.com/$owner/$repo/discussions/$number" | pup 'span.js-issue-title.markdown-title text{}' | tr -s '[:space:]' ' ' 2>/dev/null); then
    echo "Failed to get title for discussion $number" >&2
    continue
  fi

  # create a title image using ImageMagick with the same width as the body image
  echo "grabbing title"
  if ! convert -size "${width}"x100 xc:white -gravity Center -pointsize 42 -fill black -annotate 0 "$title" title_"$number".png 2>/dev/null; then
    echo "Failed to create title image for discussion $number" >&2
    continue
  fi

  # combine the title and body images into a single image
  echo "joining title and body"
  if ! convert title_"$number".png body_"$number".jpg -append "$repo"_"$number".jpg 2>/dev/null; then
    echo "Failed to combine title and body images for discussion $number" >&2
    continue
  fi
  
  echo "cleaning up docs"
  if ! cp "$repo"_"$number".jpg docs/"$repo"/archive/"$number".jpg 2>/dev/null; then
    echo "Failed to copy to archive" >&2
    continue
  fi
  
  # Move to docs to serve
  echo "moving files to /docs"
  if ! mv "$repo"_"$number".jpg docs/"$repo"/"$i".jpg 2>/dev/null; then
    echo "Failed to move files" >&2
  fi
  i=$((i-1))
done < numbers.txt

# Clean up files
if ! rm title_*.png body_*.jpg numbers.txt engine.bin 2>/dev/null; then
  echo "Failed to clean up temporary files" >&2
fi

# Move to docs to serve
echo "moving $repo json to /docs"
if ! mv response.json docs/"$repo"/ 2>/dev/null; then
  echo "Failed to move JSON" >&2
fi

# Combine into 1 poster
echo "Combine into 1 poster"
# Clean up previous poster first
rm docs/"$repo"/poster.jpg
if ! convert $(ls docs/"$repo"/*.jpg | sort -n) +append docs/"$repo"/poster.jpg 2>/dev/null; then
    echo "Failed to combine into a poster" >&2
fi

echo "Finished processing"
