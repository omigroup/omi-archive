---
layout: default
title: OMI Archive
---

<h1>OMI Archive</h1>

{% assign files = site.static_files | where: "path", "/docs/" %}
{% assign sorted_files = files | sort: "date" | reverse %}

<ul>
{% for file in sorted_files %}
  <li><a href="{{ file.path }}">{{ file.basename }}</a> - {{ file.date | date: "%B %d, %Y" }}</li>
{% endfor %}
</ul>
