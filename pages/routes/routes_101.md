---
title: Routes 101
permalink: /routes-101/
---

Pacer is all about graph traversals. To traverse the graph with Pacer, you create a __Route__.

## What is a route?

A route is a __collection__ of items (e.g. vertices or edges) that is __composable__, __lazily-loaded__ and __reusable__:

 * Routes implement Ruby's [Enumerable](http://ruby-doc.org/core-1.9.3/Enumerable.html) module (with certain exceptions).
 * We define routes by composing them with one another.
 * When we build a route, no work is done on the graph until you execute it. 
 * We can execute a route repeatedly.

<br /><br />

Alternatively, you can think of a route as a pipe, with a stream of items (e.g. vertices or edges) going into it, and a (possibly different) stream of items coming out of it.     
In fact, under the hood, Pacer routes are implemented using [Pipes](https://github.com/tinkerpop/pipes/wiki).

----

For example, consider the following query: _Find all flights, with 1 connection, from NYC to LA._

In Pacer, this query will translate into something that looks like the following route:

<br />

![Routes Example]({{site.baseurl}}/images/Routes2.png)

<br />

And the code that creates (and executes) this route will look like this:

```ruby
g.v(city: 'NYC').out_e.in_v.out_e.in_v(city: 'LA').paths
```

In the rest of this section, we will go through the different ways you can use routes.

## How to use it?

### Starting point

Every traversal needs to start somewhere in the graph. 
This starting point can be a vertex, edge, or a collection (i.e. a route) of such elements.


```ruby
# All vertices
g.v
# Some vertices
g.v.limit(100)
# Some vertex
g.v.first
# A specific vertex
g.vertex(42)

# All edges
g.e
# Some edges
g.e.limit(100)
# Some edge
g.e.first
# A specific edge
g.edge(42)
```

#### `g.v`

Get a route of all vertices in the graph `g`.

#### `g.e`

Get a route of all edges in the graph `g`.

#### `g.vertex(id)`

Get a specific vertex from the graph `g`.

#### `g.edge(id)`

Get a specific edge from the graph `g`.

### Basics Traversal

Our basic traversals involve moving between vertices and edges that are connected to each other.

```ruby
# v is a vertex object ...

# Outgoing edges
v.out_e
# Incoming edges
v.in_e
# Both, incoming and outgoing, edges
v.both_e

# e is an edge object ...
# Terminology:  out_v --e--> in_v

# The "source" vertex
e.out_v
# The "destination" vertex
e.in_v
# Both, "source" and "destination", vertices
e.both_v
```

<br />

#### `v.out_e`
Get the outgoing edges of a vertex (or a vertex route).

#### `v.in_e`
Get the incoming edges of a vertex (or a vertex route).

#### `v.both_e`
Get both, outgoing and incoming, edges of a vertex (or a vertex route).

<br />

#### `e.out_v`
Get the source vertex of an edge (or an edge route).

#### `e.in_v`
Get the destination vertex of an edge (or an edge route).

#### `e.both_v`
Get both vertices of an edge (or an edge route).

<br />

All of the basic traversal methods return route objects. 
These methods are available for single elements as well as routes, and we can combine them into more interesting traversals.

```ruby
# Follow outgoing edges to neighbouring vertices
v.out_e.in_v

# Follow incoming edges to neighbouring vertices
v.in_e.out_v

# Follow two outgoing edges and then one incoming edge
v.out_e.in_v.out_e.in_v.in_e.out_v
```
