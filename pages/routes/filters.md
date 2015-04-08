---
title: Filters
permalink: /routes-filters/
---


## Basics Filtering

Both, vertex and edge, routes can be filtered based on properties value(s).
Edge routes can also be filtered by edge label.

For example, we can define the following routes in a social network graph.

```ruby

# Find users by name
graph.v(type: 'user', name: 'Bob')

# Find users that Bob follows
graph.v(type: 'user', name: 'Bob').out_e(:follows).in_v(type: 'user')

# Find followers of users that Bob follows
graph.v(type: 'user', name: 'Bob').out_e(:follows).in_v(type: 'user').in_e(:follows).out_v(type: 'user')
```


