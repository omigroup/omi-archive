#!/bin/bash

# Create a temporary file to store the combined notes
temp_file=$(mktemp)

# Use find to search for text files recursively in subdirectories
find . -type f -name "*.txt" | while read -r file; do
    # Get the basename of the parent directory
    parent_dir=$(basename "$(dirname "$file")")

    # Get the basename of the file (without the extension)
    base=$(basename -s .txt "$file")

    # Add the header line to the temporary file
    echo -e "\n------------------------------\n" >> "$temp_file"
    echo "# $parent_dir $base" >> "$temp_file"
    echo -e "\n------------------------------\n" >> "$temp_file"

    # Append the content of the original file to the temporary file
    cat "$file" >> "$temp_file"
done

# Append the content of the temporary file to the output file
cat "$temp_file" >> "combined_notes.txt"

# Clean up the temporary file
rm "$temp_file"
