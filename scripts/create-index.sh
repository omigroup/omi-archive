#!/bin/bash

echo "# OMI Archive" > docs/index.md
echo >> docs/index.md
echo "| File Name | Size |" >> docs/index.md
echo "| --- | --- |" >> docs/index.md
for f in docs/*; do
    size=$(du -h "$f" | awk '{print $1}')
    name=$(basename "$f")
    echo "| [$name]($name) | $size |" >> docs/index.md
done

