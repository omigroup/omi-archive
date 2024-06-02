#!/bin/bash
#set -x

# Error handling function
handle_error() {
    local error_message="$1"
    echo "Error: $error_message" >&2
    # You can add additional error handling logic here, such as logging or exit codes
}

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
packages=("capture-website" "jq")

for package in "${packages[@]}"; do
    if ! command -v "$package" &> /dev/null; then
        echo "$package is not installed. Installing now..."
        case "$package" in
            "capture-website")
                if ! npm install --global capture-website-cli; then
                    handle_error "Failed to install capture-website-cli"
                fi
                ;;
            "jq")
                if ! sudo apt-get install jq -y; then
                    handle_error "Failed to install jq"
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
      discussions(first: $num, orderBy: { field: CREATED_AT, direction: DESC }) {
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
    handle_error "Failed to write GraphQL query to file"
fi

# Get a list of the past X amount of URLs
echo "Getting a list of URLs from past discussions"
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" -X POST -d @numbers.graphql "https://api.github.com/graphql" > "$owner"/"$owner"_"$repo".json

# Extract discussion numbers using jq
cat "$owner"/"$owner"_"$repo".json | jq -r '.data.repository.discussions.nodes[].number' | sort -n > numbers.txt

# Remove old files if there are any
if [ "$(ls -A "$repo"/)" ]; then
  if ! rm "$repo"/* 2>/dev/null; then
    handle_error "Failed to clean up old files"
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
      handle_error "Failed to capture website for discussion $number"
      continue
  fi

  # get the width of the body image using ImageMagick
  if ! width=$(identify -format "%w" body_"$number".jpg 2>/dev/null); then
    handle_error "Failed to get width of image body_$number.jpg"
    continue
  fi

  # get the title of the discussion using curl
  if ! title=$(curl -s "https://github.com/$owner/$repo/discussions/$number" | grep -oP '(?<=<meta name="description" content=")[^"]*' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' 2>/dev/null); then
    handle_error "Failed to get title for discussion $number"
    continue
  fi

  # create a title image using ImageMagick with the same width as the body image
  echo "grabbing title"
  if ! magick -size "${width}x100" xc:white -gravity Center -pointsize 42 -annotate 0 "$title" "png32:title_$number.png"; then
    handle_error "Failed to create title image for discussion $number"
    continue
  fi

  # combine the title and body images into a single image
  echo "joining title and body"
  if ! magick title_"$number".png body_"$number".jpg -append "$repo"_"$number".jpg; then
    handle_error "Failed to combine title and body images for discussion $number"
    continue
  fi

  echo "cleaning up docs"
  if ! cp "$repo"_"$number".jpg docs/"$repo"/archive/"$number".jpg 2>/dev/null; then
    handle_error "Failed to copy to archive"
    continue
  fi

  # Move to docs to serve
  echo "moving files to /docs"
  if ! mv "$repo"_"$number".jpg docs/"$repo"/"$i".jpg 2>/dev/null; then
    handle_error "Failed to move files"
  fi
  i=$((i-1))
done < numbers.txt

# Clean up files
if ! rm title_*.png body_*.jpg numbers.txt engine.bin 2>/dev/null; then
  handle_error "Failed to clean up temporary files"
fi

# Move to docs to serve
echo "moving $repo json to /docs"
if ! mv response.json docs/"$repo"/ 2>/dev/null; then
  handle_error "Failed to move JSON"
fi

# Combine into 1 poster
echo "Combine into 1 poster"
# Clean up previous poster first
rm docs/"$repo"/poster.jpg
if ! magick $(ls docs/"$repo"/*.jpg | sort -n) +append docs/"$repo"/poster.jpg; then
    handle_error "Failed to combine into a poster"
fi

echo "Finished processing"
