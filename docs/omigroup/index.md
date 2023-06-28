---
layout: default
---

# Directory Listing

{% for file in site.static_files %}
  {% assign file_path = file.path %}
  {% assign file_dir = file_path | split: '/' | last %}
  {% if file_dir == page.dir %}
    - [{{ file_path | remove_first: '/' }}]({{ file_path | prepend: site.baseurl }})
  {% endif %}
{% endfor %}

