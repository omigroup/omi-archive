#!/bin/bash

# Downloads github discussions as JSON + screenshot
# Run as bash script.sh owner repo
# Example: bash script.sh omigroup gltf-extensions

# check if gh is installed
if ! command -v gh &> /dev/null
then
    echo "Error: gh is not installed. Please install it from https://cli.github.com/manual/installation" >&2
    exit 1
fi

# check if capture-website-cli is installed
if ! command -v capture-website &> /dev/null
then
    echo "capture-website-cli is not installed. Installing now..."
    if ! npm install --global capture-website-cli; then
        echo "Error: Failed to install capture-website-cli" >&2
        exit 1
    fi
fi

# check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq is not installed. Installing now..."
    if ! sudo apt-get install jq -y; then
        echo "Error: Failed to install jq" >&2
        exit 1
    fi
fi

# check if pup is installed
if ! command -v pup &> /dev/null
then
    echo "pup is not installed. Installing now..."
    if ! sudo apt-get install pup -y; then
        echo "Error: Failed to install pup" >&2
        exit 1
    fi
fi

# assign command-line arguments to variables
if [ $# -ne 2 ]; then
    echo "Usage: $0 <owner> <repo>" >&2
    exit 1
fi

owner="$1"
repo="$2"

# Define the GraphQL query
QUERY_ALL=$(cat <<EOF
query {
  repository(owner: "$owner", name: "$repo") {
    discussions(first: 4) {
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
            author{ login }
            body
          }
        }
        labels(first: 30) { nodes {
          id name color description 
        } }
        
      }
 
    }
  }
}
EOF
)

# Write the GraphQL query to a file
echo "writing the graphQL query to a file"
if ! echo "$QUERY_ALL" > numbers.graphql; then
    echo "Error: Failed to write GraphQL query to file" >&2
    exit 1
fi


## Get a list of the past X amount of URLs
echo "getting a list of URLs from past discussions"
if ! gh api graphql -F owner="$owner" -F repo="$repo" -F query=@numbers.graphql | tee "$owner"-"$repo".json | jq -r '.data.repository.discussions.nodes[].number' | sort -n > numbers.txt; then
    echo "Error: Failed to get list of discussion numbers" >&2
    exit 1
fi

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
done < numbers.txt

# Clean up files
echo "cleaning up files"
if ! rm title_*.png body_*.jpg numbers.txt engine.bin numbers.graphql 2>/dev/null; then
  echo "Failed to clean up temporary files" >&2
  exit 1
fi

echo "finished processing"
