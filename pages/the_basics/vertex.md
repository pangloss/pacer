---
title: Pacer Vertices
permalink: /vertex/
---

## Vertices in a property graph

A vertex in a property graph is an object with:

 * A set of named properties.
 * A set of incoming edges.
 * A set of outgoing edges.

<br />

There are a few basic operations we need to perform on vertices in a property graph:

 * Create a vertex.
 * Delete a vertex.
 * Connect two vertices with edges.
 * Get/set the properties of a vertex.

<br />

Let's see how this is done in Pacer ...


## Creating vertices

We create a vertex using the [`create_vertex` method of the graph object]({{site.baseurl}}/graph/#create_vertex). 


## `delete!`

You can delete a vertex from the graph by calling its `delete!` method.     

 > _Note:_ 

 > 1. Like all methods that modify the graph, this methods must be called inside a transaction.
 > 2. When we delete a vertex, we also delete all of the edges that are attached to it.


## `add_edges_to`

You can add an edge to another vertex, by calling the `add_edges_to` method.

```ruby
add_edges_to(edge_label, other_vertex, properties)
```

Create (and return) a new edge to `other_vertex`.
The `edge_label` (symbol or string) argument is required, but `properties` (hash) is optional.

Vertices do not have a method to remove edges, we remove edges by [deleting them from the graph]({{site.baseurl}}/edge/#delete!). 


## Getting edges

Each of the methods below returns a _route_ (i.e. collection) of vertices.

### `out_e`

Get all outgoing edges of a vertex.

### `in_e`

Get all incoming edges of a vertex.

### `both_e`

Get both, incoming and outgoing, edges


 
## Properties

Example:

```ruby
jruby-1.7.19 :075 > v.properties
 => {"airport"=>"YYZ", "city"=>"Toronto"}

jruby-1.7.19 :076 > v[:airport]
 => "YYZ" 

jruby-1.7.19 :077 > v['city']
 => "Toronto" 

jruby-1.7.19 :078 > v[:foo]
 => nil 

jruby-1.7.19 :079 > v['foo'] = 'bar'
 => "bar" 

jruby-1.7.19 :080 > v.properties
 => {"airport"=>"YYZ", "foo"=>"bar", "city"=>"Toronto"} 

jruby-1.7.19 :081 > v[:foo] = nil
 => nil 

jruby-1.7.19 :082 > v.properties
 => {"airport"=>"YYZ", "city"=>"Toronto"}
```


 > _Note:_ We can use either strings or [symbols](http://rubylearning.com/satishtalim/ruby_symbols.html) for property names.


### `properties`

Get all properties as a hash (aka dictionary, map , object, associative array, etc).

### `[]`

The `[]` operator is used for getting and setting a specific property (just like a plain old Ruby hash).     
You can remove a property by setting its value to `nil`.




