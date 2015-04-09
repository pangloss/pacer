---
title: Traversals
permalink: /routes-traversals/
---

We have already seen the most basic traversal methods: `out_e`, `in_e`, `both_e`, `out_v`, `in_v` and `both_v`. 
Let's see what else we can do:
 

## Limit, Offset & Range 

```ruby
# Get at most 99 items
g.v.limit(99)

# Skip the first 3 items
g.v.offset(3)

# Skip the first 5 items, and get the next (at most) 3 items.
g.v.offset(5).limit(3)
# The command above is identical to
g.v.limit(3).offset(5)
```

The most intuitive use-case of `limit` and `offset` is pagination:

```ruby
page_index     = 0
items_per_page = 100

loop do 
  route = g.v.limit(items_per_page).offset(page_index * items_per_page)
  page_index += 1
  break if route.empty?
end 
``` 

You can also use the `range` method, as an alternative to `limit` and `offset`: 

```ruby
# Get the range of items from index 10 to 100 (including both).
g.v.range(10, 100)
# The route above is equivalent to
g.v.limit(91).offset(10)
```
