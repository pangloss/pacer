---
title: Additional Route Methods
permalink: /route-methods/
---

We have already seen the most basic traversal methods: `out_e`, `in_e`, `both_e`, `out_v`, `in_v` and `both_v`. 
Let's see what else we can do:
 
## Getting properties

We get properties from a route the same way we do for a single element. 


### `properties`

Get all properties (of each item in the route). This method returns a route of hash objects.

### `[]`

Get a specific property (of each item in the route). This method returns a route of objects.


> _Note:_ Setting properties is done on an individual vertex, _not_ on a route.


## `limit`, `offset`


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

## `range`

The `range` method is an alternative to combining `limit` and `offset`: 

```ruby
# Get the range of items from index 10 to 100 (including both).
g.v.range(10, 100)
# The route above is equivalent to
g.v.limit(91).offset(10)
```

 > _Note:_ You can also get a range using Ruby's `..` range syntax.     
 > For example, `g.v[10..100]`.


## `uniq`

Removes duplicates.

Example:

```ruby
jruby-1.7.19 :183 > g.v.out_e.in_v
#<V[3]> #<V[0]> #<V[3]> #<V[2]> #<V[2]>
Total: 5

jruby-1.7.19 :184 > g.v.out_e.in_v.uniq
#<V[3]> #<V[0]> #<V[2]>
Total: 3
```

## `count`

Returns the number of items in the route.

Example:

```ruby
jruby-1.7.19 :272 > g.v.count
 => 4 
```

## `frequencies`

Return a hash, mapping each item to the number of times it occurs in the route.     
For example:

```ruby
jruby-1.7.19 :321 > g.e[:airline]
"Delta"  "Air Canada"  "Delta"  "American Airlines"  "WestJet"          
Total: 5

jruby-1.7.19 :322 > g.e[:airline].frequencies
 => {"Delta"=>2, "Air Canada"=>1, "American Airlines"=>1, "WestJet"=>1} 
```


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
[#<V[3]>, #<E[6]:3-flight-1>, #<V[1]>, #<E[5]:1-flight-3>, #<V[3]>] 
[#<V[3]>, #<E[6]:3-flight-1>, #<V[1]>, #<E[4]:1-flight-0>, #<V[0]>]
Total: 2
```
 
Each of the path above is an array of alternating vertices and edges.     
Here is what the paths look like in the sample graph I am currently using in my IRB:

```
> _.each {|p| puts("#{p[0][:city]} -#{p[1][:airline]}-> #{p[2][:city]} -#{p[3][:airline]}-> #{p[4][:city]}")}

Toronto -Air Canada-> New York -Air Canada-> Toronto
Toronto -Air Canada-> New York -Delta-> Los Angeles
```


## `vertices_route?`

Return true when called on a vertex or a vertex route.

## `edges_route?`

Return true when called on an edge or an edge route.


## `Enumerable` methods

Routes implement Ruby's [Enumerable](http://ruby-doc.org/core-1.9.3/Enumerable.html) module.
It means that you can use routes like any other Ruby collection, with a few exceptions:

 * Some methods that usually return an array, return a route object.
 * Some methods have extended behaviour.      
   For example, `map`, `select` and `reject` are overridden to create steps in a lazy route rather than execute immediately as they would by default. 

The table below summarizes these methods.


| Method | Return a route | Has extended behaviour |
|--------|------------------|---------------------------------|
| `all?` |   | |
| `any?` |   | |
| `count` |  | |
| `drop` | X | |
| `first` |  | |
| `flat_map` | X | X |
| `group_by` |   | |
| `include?` |   | |
| `last` |  | |
| `map` | X | X |
| `reduce` | | |
| `reject` | X | X |
| `select` | X | X |
| `take` | X | |
| `to_a` |  | |


## Convenience methods - `in`, `out` and `both`

Vertices and vertex routes support the following three convenience methods

 - `out`, get outgoing neighbours of a vertex (or a vertex route).     
    This method is (almost) equivalent to `out_e.in_v`.
 - `in`, get incoming neighbours of a vertex (or a vertex route).     
    This method is (almost) equivalent to `in_e.out_v`.
 - `both`, get all neghbours (i.e. the union of `out` and `in`).

> While useful for exploration in the console, they are often not a good idea in production. They don't preserve information about which edge was
> followed in the traversal, making it impossible to use certain useful tools like `subgraph` or the graph export tool rely on that information.

Usage:

- `v.in(:edge_label)` only with the given edge label.
- `v.in(:edge_label, :alternate_edge_label)` only with one of the given edge labels.
- `v.in(vertex_property: "matching value")` only with the exact matching properties.
- `v.in { |vertex| }` only when the block returns a [truthy] value.
- `v.in(Extension)` Extend results with the given extension.
- `v.in(:edge_label, Extension, vertex_property: "matching value") { |vertex| }` combined



[truthy]: https://gist.github.com/jfarmer/2647362