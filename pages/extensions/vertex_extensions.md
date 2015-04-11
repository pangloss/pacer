---
title: Vertex Extensions
permalink: /vertex-extensions/
---


Let's see an example of how we might extend a simple graph containing airports (vertices) and flights (edges).

 > You can paste the code examples below directly in the IRB, or save them in a file, and call `load(path_to_file)`.


## Create some data

In order to use our extension, let's create a simple test graph:

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


## Create the `Airport` extension

```ruby
module Airport

    module Vertex

        def pretty_print
            "#{self[:airport]} airport, #{self[:city]}"
        end
        
    end


    module Route

    	def departures
            self.out_e(:flight)
        end

        def arrivals
            self.in_e(:flight)
        end

    end

end
```


 > In Pacer, a single vertex can easily be wrapped in a route (with a single element). Therefore,
 >
 >  - A single vertex gets extended by both `Vertex` and `Route` methods.
 >  - A route of vertices is extended only by both `Route` methods.


## Use the `Airport` Extension

