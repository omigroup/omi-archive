---
layout: default
---

<h1>OMI Archive</h1>

<ul>
{% for file in site.static_files %}
  {% if file.path contains 'docs/' %}
    <li><a href="{{ file.path }}">{{ file.path | remove: 'docs/' }}</a></li>
  {% endif %}
{% endfor %}
</ul>

