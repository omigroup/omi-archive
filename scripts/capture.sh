#!/bin/bash

# loop through each line in the numbers.txt file
while read -r number
do
  # capture the website as a JPEG image
  capture-website "https://github.com/omigroup/omigroup/discussions/$number" --type=jpeg --quality=1 --full-page --element=".discussion" --scale-factor=2 --output=body_$number.jpg --overwrite

  # get the width of the body image using ImageMagick
  width=$(identify -format "%w" body_$number.jpg)

  # get the title of the discussion using curl and pup
  title=$(curl -s "https://github.com/omigroup/omigroup/discussions/$number" | pup 'span.js-issue-title.markdown-title text{}' | tr -s '[:space:]' ' ')

  # create a title image using ImageMagick with the same width as the body image
  convert -size ${width}x100 xc:white -gravity Center -pointsize 64 -fill black -annotate 0 "$title" title_$number.png

  # combine the title and body images into a single image
  convert title_$number.png body_$number.jpg -append combined_$number.jpg
done < numbers.txt
