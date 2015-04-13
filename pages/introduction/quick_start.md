---
title: Quick Start
permalink: /quick_start/
---

It is time to see Pacer in action. Let's open the IRB, and see how it is done. 

## Create and Populate a Graph


Let's create a fairly simple graph data set - Vertices represent airports, 
and edges represent flights offered from one airport to another.

Paste the following code in the IRB:

```ruby
require 'pacer'

# Create an in-memory TinkerGraph
g = Pacer.tg()

g.transaction do # optional with TinkerGraph

  lax = g.create_vertex({airport: 'LAX', city: 'Los Angeles'})
  lga = g.create_vertex({airport: 'LGA', city: 'New York'})
  sfo = g.create_vertex({airport: 'SFO', city: 'San Francisco'})
  yyz = g.create_vertex({airport: 'YYZ', city: 'Toronto'})
  
  lga.add_edges_to(:flight, lax, {airline: 'Delta'})
  lga.add_edges_to(:flight, yyz, {airline: 'Air Canada'})
  yyz.add_edges_to(:flight, lga, {airline: 'Air Canada'})
  lax.add_edges_to(:flight, yyz, {airline: 'Delta'})
  lax.add_edges_to(:flight, sfo, {airline: 'WestJet'})
  lax.add_edges_to(:flight, sfo, {airline: 'American Airlines'})

end
```


Vertices can contain any number of properties (including 0), specified as a hash.   
In our case, vertices represent airports, and we created each vertex with two properties, `airport` and `city`.    
For example:

```ruby
lax = g.create_vertex({airport: 'LAX', city: 'Los Angeles'})
```



Edges are directed, and _must_ have a label. 
In addition to that, just like vertices, they can contain an arbitrary hash of properties.     
For example, the following line creates an edge from the vertex `lga` to `lax`, with the label `:flight`, and a single property `airline`, whose value is `'Delta'`.

```ruby
lga.add_edges_to(:flight, lax, {airline: 'Delta'})
```

## Traverse The Graph

Get all vertices

```ruby
g.v()
```

Filter vertices by property (get all vertices whose `airport` is `LGA`)

```ruby
g.v({airport: 'LGA'})
```

Access properties

```ruby
g.v({airport: 'LGA'})['city']
```

Get edges based on vertices.

```ruby
# Outgoing edges
g.v({airport: 'LGA'}).out_e()
# Incoming edges
g.v({airport: 'LGA'}).in_e()
# Both
g.v({airport: 'LGA'}).both_e()
```

__Example:__ Get all airlines flying in or out of LaGuardia airport

```ruby
g.v({airport: 'LGA'}).both_e()['airline'].uniq
```

If you run the command above on the irb, you should see the output:

```ruby
"Air Canada"        "American Airlines" "Delta"            
Total: 3
#<GraphV -> V-Property(airport=="LGA") -> bothE -> Obj(airline) -> decode -> uniq>
```

We can also get edges from the graph.

```ruby
g.e()
```

And filter by property

```ruby
g.e({airline: 'Delta'})
```

Get vertices based on edges

```ruby
# In an edge from x to y, we call x the _out-vertex_, and y the _in-vertex_.

# In-vertices
g.e({airline: 'Delta'}).in_v
# Out-vertices
g.e({airline: 'Delta'}).out_v
# Both
g.e({airline: 'Delta'}).both_v
```

__Example:__ Get all cities that Delta flies from/to.

```ruby
g.e({airline: 'Delta'}).both_v['city'].uniq
```

If you run the command above on the irb, you should see the output:

```ruby
"Los Angeles" "Toronto"     "New York"   
Total: 3
#<GraphE -> E-Property(airline=="Delta") -> bothV -> Obj(city) -> decode -> uniq>
```
