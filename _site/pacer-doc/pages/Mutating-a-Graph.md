 * [Creating Vertices](#creating-vertices) 
 * [Creating Edges](#creating-edges)
 * [Deleting Elements](#deleting-elements)
 * [Updating Elements](#updating-elements)
 * [A Note About Transactions](#a-note-about-transactions)

----

### Creating Vertices

Create a vertex without any properties
```
v = g.create_vertex()
```

Create a vertex with some properties
```
v = g.create_vertex({type: 'airport', code: 'LGA', name: 'LaGuardia Airport', city: 'New York', country_code: 'US'})
```

### Creating Edges

Pacer edges are directed and labeled, and can optionally contain named properties.    

Create an edge from vertex `u` to vertex `v`, with the label `:flight`.
```
u = g.create_vertex({type: 'airport', code: 'LGA'})
v = g.create_vertex({type: 'airport', code: 'LAX'})
u.add_edges_to(:flight, v)
```

Create an edge with some properties
```
u.add_edges_to(:flight, v, {flight_code: 'AC524', aircraft: '747'})
```

Notice that we can create multiple edges from `u` to `v` with the same label.

We can add edges from a vertex `u` to multiple vertices.
```
w = g.create_vertex()
u.add_edges_to(:foo, [v,w])
```

In the example above, the second argument was an array, but we can also pass a route of vertices.     
For example, the following command creates an edge from the vertex `u` to any other vertex in the graph (including `u` itself)
```
u.add_edges_to(:bar, g.v())
```

In fact, the `add_edges_to` can also be applied to a route of edges.     
For example, the following command creates an edge from every vertex in the graph to `u`.
```
g.v().add_edges_to(:foo, u)
```

As you might expect, we can also create edges from many vertices to many vertices.
```
g.v().add_edges_to(:foo, g.v())
```

### Deleting Elements

Deleting a single vertex
```
g.v().first().delete!
```
Deleting a vertex will delete all edges to/from that vertex.

We can `delete!` all vertices in a route.
```
g.v().delete!
```

Similarly, we can delete a single edge
```
g.e().first().delete!
```
Or all edges in a route
```
g.e().delete!
```

### Updating Elements

We can add a property (or update it, if it already exists) to a vertex.
```
g.v().first()[:foo] = 'bar'
```
We can also delete a property (if it exists)
```
g.v().first()[:foo] = nil
```
The same syntax works for edges.
```
# Add/set a property
g.e().first()[:foo] = 'bar'
# Delete a property
g.e().first()[:foo] = nil
```

Notice that the syntax above does not work with routes. 
That is, calling `g.v()[:foo] = 'bar'` will result in `NoMethodError`.

In order to update a property of every element in a route, you can use `bulk_job`.
```
g.v().bulk_job {|vertex| vertex[:foo] = 'bar'}
```

### A Note About Transactions

Most graph databases require all changes (i.e. create, update or delete) to a graph to take place inside of a transaction.

```
require 'pacer-neo4j'
g = Pacer.neo4j('/path/to/graph_dir')
g.transaction do
    # Code that mutates the graph goes here ...
end
```

Transactions are not required by the in-memory [TinkerGraph](https://github.com/tinkerpop/blueprints/wiki/TinkerGraph).
