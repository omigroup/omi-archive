#!/bin/bash

# Read numbers.txt line by line
while read -r number; do
  chromium --headless --disable-gpu --print-to-pdf=$number.pdf https://github.com/omigroup/gltf-extensions/discussions/$number
done < numbers.txt
