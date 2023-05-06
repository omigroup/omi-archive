#!/bin/bash

# Set the directory to scan
dir="docs"

# Create an empty index.md file
echo "# OMI Archive" > "$dir"/index.md
echo >> "$dir"/index.md
echo "Last GitHub discussions from different repos, usually in order of 1 = last week, 2 = 2 weeks ago, etc" >> "$dir"/index.md
echo >> "$dir"/index.md
echo "| File Name | Size |" >> "$dir"/index.md
echo "| --- | --- |" >> "$dir"/index.md

# Loop through each file in the directory
for file in $(find "$dir" -type f | sort); do
    # Get the filename and size of the file
    size=$(du -h "$file" | awk '{print $1}')

    # Remove the leading "docs/" directory from the filename
    filename="${file#docs/}"

    # Append the filename and size to the markdown table
    echo "| [$filename]($filename) | $size |" >> "$dir"/index.md
done
