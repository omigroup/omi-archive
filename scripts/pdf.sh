#!/bin/bash

repo="$1"

find docs/$repo/archive -maxdepth 1 -type f -iname "*.jpg" -exec basename {} .jpg \; | sort -n > "$repo/numbers.txt"

# Read numbers.txt line by line
while read -r number; do
  pdf_file="$repo/pdf/$number.pdf"
  
  # Check if the PDF file already exists
  if [ ! -f "$pdf_file" ]; then
    chromium --headless --disable-gpu --print-to-pdf="$pdf_file" "https://github.com/omigroup/$repo/discussions/$number"
  fi
done < "$repo/numbers.txt"

# clean up files
rm "$repo/numbers.txt"
