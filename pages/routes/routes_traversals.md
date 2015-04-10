---
title: Traversals
permalink: /routes-traversals/
---

We have already seen the most basic traversal methods: `out_e`, `in_e`, `both_e`, `out_v`, `in_v` and `both_v`. 
Let's see what else we can do:
 
## Getting properties

In almost every useful application, you will need to read the properties on the vertices and edges in the graph.


### `properties`


The `properties` method is used to get all the properties of vertices and/or edges. 

_Example:_ The route `g.v.properties` will produce the following output, when executed in the IRB:

```
{"code"=>"YYZ", "city"=>"Toronto"}       {"code"=>"SFO", "city"=>"San Francisco"} {"code"=>"LGA", "city"=>"New York"}     {"code"=>"LAX", "city"=>"Los Angeles"}  
Total: 4
```

### `[]`

Routes support the `[]` operator, which allows you to access a specific property:

```ruby
g.v['city']
```
The command above will return a route of strings. When I executed it in my IRB, I got the following output:

```
"Toronto"       "San Francisco" "New York"      "Los Angeles"  
Total: 4
```

> _Note:_ Routes allow you to read the properties of graph elements. Writing (i.e. create, update or delete) properties is done on an individual vertex, _not_ on a route.


## `paths`

When a traversal walks through the graph, Pacer can keep track of what it encounters on each step along the way. You can access that with the Paths Route.

For example, in a graph where vertices are airports and edges are flights, we could ask for all cities we can reach by taking exactly two flight from Toronto:

```ruby
g.v(city: 'Toronto').out_e.in_v.out_e.in_v[:city]
```

In my IRB, the output of the above route is:

```
"Toronto"     "Los Angeles"
Total: 2
```

If we want to know the full path from New York to each other city, we can use the `paths` method:

```ruby
g.v(city: 'New York').out_e.in_v.out_e.in_v.paths
```

Which, in my IRB, results in the following output:

```
[#<V[3]>, #<E[6]:3-flies_to-1>, #<V[1]>, #<E[5]:1-flies_to-3>, #<V[3]>] 
[#<V[3]>, #<E[6]:3-flies_to-1>, #<V[1]>, #<E[4]:1-flies_to-0>, #<V[0]>]
Total: 2
```
 
Each of the path above is an array of alternating vertices and edges.     
Here is what the paths look like in the sample graph I am currently using in my IRB:

```
> _.each {|p| puts("#{p[0][:city]} -#{p[1][:airline]}-> #{p[2][:city]} -#{p[3][:airline]}-> #{p[4][:city]}")}

Toronto -Air Canada-> New York -Air Canada-> Toronto
Toronto -Air Canada-> New York -Delta-> Los Angeles
```


## `limit`, `offset` and `range` 


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

The `range` method is an alternative to combining `limit` and `offset`: 

```ruby
# Get the range of items from index 10 to 100 (including both).
g.v.range(10, 100)
# The route above is equivalent to
g.v.limit(91).offset(10)
```

