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

## Starting A Traversal

Every traversal needs to start somewhere in the graph. 
This starting point can be a vertex, edge, or a collection (i.e. a route) of such elements.

Here is how you would get a starting point, using a reference to a graph, `g`.

```ruby
# Single vertex
g.v.first
# Single vertex by id
g.vertex(some_vertex_id)
```

```ruby
# Single edge
g.e.first
# Single edge by id
g.edge(some_edge_id)
```

```ruby
# A route vertices
g.v.limit(100)
# A route edges
g.e.limit(100)
```


## Basics Traversal

Starting from a vertex (or a vertex route), `v`, we can get adjacent edges:

```ruby
# Outgoing edges
v.out_e
# Incoming edges
v.in_e
# Both, incoming and outgoing, edges
v.both_e
```

Similarly, starting from an edge (or an edge route), `e`, we can get adjacent vertices:

```ruby
# The "source" vertex
e.out_v
# The "destination" vertex
e.in_v
# Both, "source" and "destination", vertices
e.both_v
```

<span class="label label-info">Terminology:</span> We say that an edge goes from its _out vertex_ to its _in vertex_ (or, in ascii, `out_v --e--> in_v`).

Combining the basic traversals above, we can follow edges and get the neighbours of a vertex (or a route of vertices).

```ruby
# Follow outgoing edges
v.out_e.in_v
# Follow incoming edges
v.in_e.out_v
```
