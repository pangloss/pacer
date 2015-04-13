---
title: Pacer Edges
permalink: /edge/
---

## Edges in a property graph

An edge, in a property graph, connects two vertices, and has:

 * A set of named properties.
 * A source vertex (aka _out vertex_).
 * A destination vertex (aka _in vertex_).

<br />

 > _Note:_ Pacer edges are directed, but we can always simulate an undirected graph by traversing edges in both (incoming and outgoing) directions.

<br />

Let's see the basic edge operations in Pacer ...


## Creating edges

Edges are created by [calling the `add_edges_to` method on a vertex]({{site.baseurl}}/vertex/#add_edges_to).     


## `delete!`

You can delete an edge from the graph by calling its `delete!` method.     
_Note:_ Like all methods that modify the graph, this methods must be called inside a transaction.


## Getting vertices

We use [Blueprints](https://github.com/tinkerpop/blueprints/wiki) terminology, and say that an edge goes from its _out vertex_ into its _in vertex_.    
That is, `out_vertex --edge--> in_vertex`.

### `out_v`

Get the source vertex.

### `in_v`

Get the destination vertex.

### `both_v`

Get both vertices.

 > _Note:_ All the methods above return a route (i.e. A collection) of vertices. In the case of `out_v` and `in_v` the route contains a single vertex.


## Properties

Getting/setting edge properties works the same way as [getting/setting vertex properties]({{site.baseurl}}/vertex/#properties).

### `properties`

The `properties` methods is used for getting all properties, as a hash object.

### `[]`

The `[]` operator is used for getting and setting a specific property.


