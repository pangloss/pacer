---
title: Quick Start
permalink: /quick_start/
---

It is time to see Pacer in action. Let's open the IRB, and see how it is done. 

## Create and Populate a Graph


Let's create a fairly simple graph data set - Vertices represent airports, 
and edges represent flights offered from one airport to another.

```ruby
require 'pacer'

# Create an in-memory TinkerGraph
g = Pacer.tg()

g.transaction do # optional with TinkerGraph

  lax = g.create_vertex({code: 'LAX', city: 'Los Angeles'})
  lga = g.create_vertex({code: 'LGA', city: 'New York'})
  sfo = g.create_vertex({code: 'SFO', city: 'San Francisco'})
  yyz = g.create_vertex({code: 'YYZ', city: 'Toronto'})
  
  lga.add_edges_to(:flies_to, lax, {airline: 'Delta'})
  lga.add_edges_to(:flies_to, yyz, {airline: 'Air Canada'})
  yyz.add_edges_to(:flies_to, lga, {airline: 'Air Canada'})
  lax.add_edges_to(:flies_to, yyz, {airline: 'Delta'})
  lax.add_edges_to(:flies_to, sfo, {airline: 'WestJet'})
  lax.add_edges_to(:flies_to, sfo, {airline: 'American Airlines'})

end
```


Vertices can contain any number of properties (including 0), specified as a hash.   
In our case, vertices represent airports, and we created each vertex with two properties, `code` and `city`.    
For example:

```ruby
lax = g.create_vertex({code: 'LAX', city: 'Los Angeles'})
```



Edges are directed, and _must_ have a label. 
In addition to that, just like vertices, they can contain an arbitrary hash of properties.     
For example, the following line creates an edge from the vertex `lga` to `lax`, with the label `:flies_to`, and a single property `airline`, whose value is `'Delta'`.

```ruby
lga.add_edges_to(:flies_to, lax, {airline: 'Delta'})
```

## Traverse The Graph

Get all vertices

```ruby
g.v()
```

Filter vertices by property (get all vertices whose `code` is `LGA`)

```ruby
g.v({code: 'LGA'})
```

Access properties

```ruby
g.v({code: 'LGA'})['city']
```

Get edges based on vertices.

```ruby
# Outgoing edges
g.v({code: 'LGA'}).out_e()
# Incoming edges
g.v({code: 'LGA'}).in_e()
# Both
g.v({code: 'LGA'}).both_e()
```

__Example:__ Get all airlines flying in or out of LaGuardia airport

```ruby
g.v({code: 'LGA'}).both_e()['airline'].uniq
```

If you run the command above on the irb, you should see the output:

```ruby
"Air Canada"        "American Airlines" "Delta"            
Total: 3
#<GraphV -> V-Property(code=="LGA") -> bothE -> Obj(airline) -> decode -> uniq>
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
