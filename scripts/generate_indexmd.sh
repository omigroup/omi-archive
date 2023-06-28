#!/bin/bash

generate_index_md() {
    local dir="$1"
    local indent="${2:-}"
    
    # Create the index.md file
    echo -e "---\nlayout: default\n---" > "$dir/index.md"
    
    # Print directory listing
    for file in "$dir"/*; do
        if [[ -d "$file" ]]; then
            local subdir="${file##*/}"
            echo "${indent}- [${subdir}/](${subdir}/)" >> "$dir/index.md"
            generate_index_md "$file" "    ${indent}"
        elif [[ -f "$file" ]]; then
            local filename="${file##*/}"
            echo "${indent}- [${filename}](${filename})" >> "$dir/index.md"
        fi
    done
}

# Start from the 'docs' directory
root_dir="docs"

# Call the function recursively for each subdirectory
generate_index_md "$root_dir"
