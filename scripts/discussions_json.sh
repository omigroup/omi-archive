#!/bin/bash

# Downloads github discussions as JSON + screenshot
# Run as bash script.sh owner repo
# Example: bash script.sh omigroup gltf-extensions

# assign command-line arguments to variables
if [ $# -ne 3 ]; then
    echo "This script archives the GitHub Discussions" >&2
    echo "Usage: $0 <owner> <repo> <number of discussions>" >&2
    exit 1
fi

owner="$1"
repo="$2"
num="$3"

# Define the GraphQL query
QUERY_ALL=$(cat <<EOF
query {
  repository(owner: "$owner", name: "$repo") {
    discussions(last: $num) {
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

echo "finished processing"
