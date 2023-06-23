#!/bin/bash

url_file="$1"

while IFS= read -r url; do
  # Extract the dirname and basename
  dirname=$(dirname "$url")
  basename=$(basename "$dirname")

  # Download the file and save with the basename
  wget -O "$basename.md" "$url"
done < "$url_file"


# for i in *.md; do mdpdf $i; done
