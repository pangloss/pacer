---
title: Filtering by extensions
permalink: /filter-by-extension/
---


Earlier, we created a simple [vertex extension, `Airport`]({{site.baseurl}}/vertex-extensions/#create-an-extension), but we forgot to ask an important question:

 * What if some vertices in our graph are not airports?    
   For example, we could have vertices representing airplanes, people, runways, etc.
 

Essentially, we want to be able to do the following:

 * Get vertices that correspond to airports, and extend them with the `Airport` extension.


## `route_conditions`

You can define a `route_conditions` method that will tell Pacer which vertices can be extended by an extension.

In most applications, filtering by extensions is very common, and needs to be fast. 
Therefore, `route_conditions` only allows for very simple filtering conditions:

 * Exact property match with a single value.
 * Exact property match with a set of values (i.e. exact match with one of the items in the set).

<span class="label label-info">Tip:</span> Save a `_type` property with each vertex, create an index on the key `_type` and use it for filtering.


## See it in action

First, let's re-create our simple test data. This time, we will create a `_type` property in each vertex.

```ruby
g = Pacer.tg()

g.transaction do # optional with TinkerGraph

  lax = g.create_vertex({_type: :airport, airport: 'LAX', city: 'Los Angeles'})
  lga = g.create_vertex({_type: :airport, airport: 'LGA', city: 'New York'})
  sfo = g.create_vertex({_type: :airport, airport: 'SFO', city: 'San Francisco'})
  yyz = g.create_vertex({_type: :airport, airport: 'YYZ', city: 'Toronto'})

  lga.add_edges_to(:flight, lax, {airline: 'Delta'})
  lga.add_edges_to(:flight, yyz, {airline: 'Air Canada'})
  yyz.add_edges_to(:flight, lga, {airline: 'Air Canada'})
  lax.add_edges_to(:flight, yyz, {airline: 'Delta'})
  lax.add_edges_to(:flight, sfo, {airline: 'WestJet'})
  lax.add_edges_to(:flight, sfo, {airline: 'American Airlines'})

end
```

Next, we will define the `route_conditions` method, so that only vertices whose `_type` property is `airport` will get extended by our `Airport` extension.

```ruby

module Airport

    def self.route_conditions(graph)
        {_type: :airport}
    end


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

Now, let's test our changes in the IRB.

```ruby
# Just as before, extend a vertex route with our Airport extension
jruby-1.7.19 :061 > g.v(Airport)
#<V[3] YYZ airport, Toronto>  #<V[2] SFO airport, San Francisco>  #<V[1] LGA airport, New York>   #<V[0] LAX airport, Los Angeles>  
Total: 4

# Create a non-airport vertex (we're using TinkerGraph, so we don't need a transaction)
jruby-1.7.19 :062 > g.create_vertex
 => #<V[10]> 

# The new vertex is filtered out, when we extend the route with our Airport extension
jruby-1.7.19 :063 > g.v(Airport)
#<V[3] YYZ airport, Toronto>  #<V[2] SFO airport, San Francisco>  #<V[1] LGA airport, New York>   #<V[0] LAX airport, Los Angeles>  
Total: 4

# Create another vertex, this time with a '_type' property whose value is 'airport'.
jruby-1.7.19 :064 > g.create_vertex({_type: :airport, airport: 'MSY', city: 'New Orleans'})
 
 # The new vertex is included in the result, when we filter using our `Airport` extension.
jruby-1.7.19 :065 > g.v(Airport)
#<V[3] YYZ airport, Toronto>       #<V[2] SFO airport, San Francisco> #<V[1] LGA airport, New York>      #<V[0] LAX airport, Los Angeles>  
#<V[11] MSY airport, New Orleans> 
Total: 5
```


## Indexing our filtering property

Since the `_type` property will be used for filtering, we better make sure it is indexed:

```ruby
# Filter by extension, without an index
jruby-1.7.19 :072 > g.v(Airport)
#<V[3] YYZ airport, Toronto>       #<V[2] SFO airport, San Francisco> #<V[1] LGA airport, New York>      #<V[0] LAX airport, Los Angeles>  
#<V[11] MSY airport, New Orleans> 
Total: 5
 => #<GraphV -> V-Property(Airport)> 

# Create the index
jruby-1.7.19 :073 > g.create_key_index :_type
 => nil 

# Filter by extension, with an index
jruby-1.7.19 :074 > g.v(Airport)
#<V[3] YYZ airport, Toronto>       #<V[2] SFO airport, San Francisco> #<V[1] LGA airport, New York>      #<V[0] LAX airport, Los Angeles>  
#<V[11] MSY airport, New Orleans> 
Total: 5
 => #<V-Index(_type: :airport) -> V>
```

Notice the difference in output before and after we create the index:

 - `#<GraphV -> V-Property(Airport)>` vs `#<V-Index(_type: :airport) -> V>`.

The IRB output indicates how Pacer implements a query/traversal.     
In this case, we can see that, once we created an index on the `_type` property, Pacer uses it automatically.



