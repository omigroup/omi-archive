---
layout: default
---

# Directory Listing

{% assign base_url = site.baseurl | append: "/" %}
{% assign current_url = page.url | remove: "/" %}

{% for file in site.static_files %}
  {% assign file_url = file.path | remove: base_url | remove_first: "/" %}
  {% if file_url contains current_url %}
    {% assign file_name = file_url | remove: current_url | remove_first: "/" %}
    - [{{ file_name }}]({{ file_url | prepend: base_url }})
  {% endif %}
{% endfor %}

