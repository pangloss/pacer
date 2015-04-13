---
title: Pacer Graph
permalink: /graph/
---


Pacer provides a graph object that abstracts the [underlying graph database]({{site.baseurl}}/suppoted_graph_databases/).
Let's see the common methods you will use on such a graph object, `g`.



## Getting elements

We can get vertices and edges from the graph using the following methods:

### `vertex(id)`

Get the vertex with the specified id (or `nil` if there is no such vertex).

### `edge(id)`

Get the edge with the specified id (or `nil` if there is no such edge).

### `v`

Get all vertices.

### `e`

Get all edges.


 > The `v` and `e` methods return a _route_ object.     
 > Routes are a main concept in Pacer, and we will look at them in detail later on.
 > For now, all you need to know is that a route is a collection of items. 


## Creating elements

### `create_vertex`

Create and return a vertex object. 
The `properties` (hash) argument is optional.     

```ruby
g.create_vertex(properties)
```

 > _Note:_ In most graph databases, you must call `create_vertex` inside a transaction.

### Edges

Edges are created by [calling the `add_edges_to` method on a vertex object]({{site.baseurl}}/vertex/#add_edges_to).


## Transactions

### The `transaction` method

Most graph databases support transactions (the in-memory TinkerGraph is the exception).
In fact, they require any operation that changes the graph to be wrapped in a transaction .
You can do that by passing a block to the `transaction` method:

```ruby
g.transaction do
    # Code that changes the graph goes here ...
end
```

### Committing & rolling back

For full flexibility, this method passes a `commit` and `rollback` objects to the block. 
You can commit/rollback the transaction by calling the `call` method on the appropriate object: 

```ruby
g.transaction do |commit_obj, rollback_obj|
    # Make some changes to the graph ...
    
    # If you want to save the changes
    commit_obj.call

    # If something went wrong
    rollback_obj.call

end
```

## Indices

In most cases, we traverse through the graph as follows:
 1. Search for a starting point (e.g. a vertex).
 2. Start traversing by following edges.

In order for the first step (search) to be fast, graph databases (and databases in general) use indices.     
For example, if your application frequently searches for vertices based on their `email` property, you may want to create an index for this property.

Once an index is created, Pacer makes things easy by **auto-selecting the best available index**. 

### `create_key_index`

Indices can be created using `create_key_index` for either vertices or edges. By default, all indices are at the scope of the entire graph, though there may be the possibility
of using other strategies in vendor-specific code. Indices will be built when created, so this call can take a significant amount of time on a large
graph.

Usage:

- `g.create_key_index(:property_name)` By default, vertex indices are created.
- `g.create_key_index(:property_name, :vertex, opts_hash)` Explicitly creating vertex index with implementation-specific options passed through
- `g.create_key_index(:property_name, :edge)` Create an edge index

### `drop_key_index`

Usage:

- `g.drop_key_index(:property_name, :vertex)`
- `g.drop_key_index(:property_name, :edge)`

