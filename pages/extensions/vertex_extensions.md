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


## Create an extension

```ruby
module Airport

    module Vertex

        def short_description
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

### A note on vertices vs. routes

In Pacer, a single vertex can easily be wrapped in a route (containing a single element).     
Therefore,

  - A single vertex gets extended by both `Vertex` and `Route` methods.
  - A route of vertices is extended only by both `Route` methods.

<span class="label label-info">Tip:</span> If a method makes sense for both, a single item and a collection, define it as a Route method. 
If it only makes sense for a single item, define it as a Vertex method.

## Use the extension

At this point, we can extend routes and vertices with the `Airport` extension.

```ruby
# The Airport module/extension 
jruby-1.7.19 :112 > Airport
 => Airport 

# Extending a vertex route with the Airport extension
jruby-1.7.19 :113 > airports = g.v(Airport)
#<V[3]> #<V[2]> #<V[1]> #<V[0]>
Total: 4

# Getting a single vertex out of the extended route
jruby-1.7.19 :114 > airport = airports.first
```

Notice that a route gets extended with the `departures` and `arrivals` methods, and a single vertex gets extended with `departures`, `arrivals` and `short_description`.

```ruby
# Calling the arrivals method on a route
jruby-1.7.19 :116 > airports.arrivals
#<E[7]:0-flight-3> #<E[5]:1-flight-3> #<E[9]:0-flight-2> #<E[8]:0-flight-2> #<E[6]:3-flight-1> #<E[4]:1-flight-0>
Total: 6

# Calling the departures method on a vertex
jruby-1.7.19 :117 > airport.departures
#<E[6]:3-flight-1>
Total: 1

# Calling pretty print on a vertex
jruby-1.7.19 :118 > airport.short_description
 => "YYZ airport, Toronto" 

# Trying to call short_description on a route will result in an error
jruby-1.7.19 :119 > airports.short_description
NoMethodError
```


### The `display_name` method

The `display_name` is a special vertex method - If it is defined, Pacer will use it to print items to the console.      

For example, in our `Airport` extension, let change the name of the `short_description` method to be `display_name`:

```ruby
module Airport

    module Vertex

        def display_name
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

Now, when we run queries in the IRB, their output will look like this:

```ruby
jruby-1.7.19 :171 > g.v(Airport)
#<V[3] YYZ airport, Toronto>       #<V[2] SFO airport, San Francisco> #<V[1] LGA airport, New York>      #<V[0] LAX airport, Los Angeles>  
Total: 4
```


