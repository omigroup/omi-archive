#!/bin/bash

echo "# OMI Archive" > docs/index.md
echo "| File Name | Size |" >> docs/index.md
echo "| --- | --- |" >> docs/index.md

for f in docs/*
do
  printf "| %s | %.2fKB |\n" "$(basename "$f")" "$(du -k "$f" | cut -f1)" >> docs/index.md
done

