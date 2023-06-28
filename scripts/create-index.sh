#!/bin/bash

# Set the directory to scan
dir="docs"

generate_index_html() {
    local dir="$1"
    local parent_dir=$(dirname "$dir")
    
    # Create an empty index.html file
    cat << EOF > "$dir/index.html"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>OMI Archive</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
    }
    h1 {
      font-size: 24px;
      margin-bottom: 10px;
    }
    p {
      margin-bottom: 20px;
    }
    table {
      border-collapse: collapse;
      width: 100%;
    }
    th, td {
      border: 1px solid #ddd;
      padding: 8px;
      text-align: left;
    }
    th {
      background-color: #f2f2f2;
    }
    a {
      color: #0366d6;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
  <h1>OMI Archive</h1>
  <p>Last GitHub discussions from different repos, usually in order of 1 = last week, 2 = 2 weeks ago, etc</p>
  <table>
    <tr><th>File Name</th><th>Size</th></tr>
EOF

    if [[ "$parent_dir" != "." ]]; then
        echo "<tr><td><a href='../index.html'>Go Back</a></td><td></td></tr>" >> "$dir/index.html"
    fi

    # Loop through each file and directory in the current directory
    for entry in "$dir"/*; do
        if [[ -d "$entry" ]]; then
            local subdir="${entry##*/}"
            echo "<tr><td><a href='${subdir}/index.html'>$subdir/</a></td><td></td></tr>" >> "$dir/index.html"
            generate_index_html "$entry"
        elif [[ -f "$entry" ]]; then
            local filename="${entry##*/}"
            local size=$(du -h "$entry" | awk '{print $1}')
            echo "<tr><td><a href='$filename'>$filename</a></td><td>$size</td></tr>" >> "$dir/index.html"
        fi
    done

    cat << EOF >> "$dir/index.html"
  </table>
</body>
</html>
EOF
}

# Start from the 'docs' directory
root_dir="docs"

# Call the function recursively for each subdirectory
generate_index_html "$root_dir"
