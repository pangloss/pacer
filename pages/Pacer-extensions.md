---
title: Pacer Extensions
permalink: /pacer-extensions/
---

Pacer extensions are a powerful tool that allows developers to:
 * Process the graph using familiar object-oriented techniques.
 * Extend graph elements (i.e. vertices and edges) with domain-specific functionality.

![Pacer Extensions]({{site.baseurl}}/images/Extensions1.png)

Let's see an example ...

### Setup

Create a basic data set that will be used in this example.

```ruby
require 'Pacer'

g = Pacer.tg()

lax = g.create_vertex({type: 'airport', code: 'LAX', city: 'Los Angeles'})
lga = g.create_vertex({type: 'airport', code: 'LGA', city: 'New York'})
sfo = g.create_vertex({type: 'airport', code: 'SFO', city: 'San Francisco'})
yyz = g.create_vertex({type: 'airport', code: 'YYZ', city: 'Toronto'})

lga.add_edges_to(:flies_to, lax, {airline: 'Delta'})
lga.add_edges_to(:flies_to, yyz, {airline: 'Air Canada'})
yyz.add_edges_to(:flies_to, lga, {airline: 'Air Canada'})
lax.add_edges_to(:flies_to, yyz, {airline: 'Delta'})
lax.add_edges_to(:flies_to, sfo, {airline: 'WestJet'})
lax.add_edges_to(:flies_to, sfo, {airline: 'American Airlines'})
```

### Our First (Vertex) Extension

Since our vertices represent airports, we will extend them with an `Airport` module.     
Save the following code in a file called `example.rb` 

```ruby
module Example

	module Airport

		module Vertex

			def display_name
				"#{self[:code]}, #{self[:city]}"
			end
		end


		module Route

			def departures
				out_e()
			end

			def arrivals
				in_e()
			end
		
		end

	end
end
```

Let's see how we can use the `Example::Airport` extension.

```ruby
irb(main):207:0> load('path/to/example.rb')

irb(main):209:0> g.v()
#<V[3]> #<V[2]> #<V[1]> #<V[0]>
Total: 4
#<GraphV>

irb(main):210:0> g.v(Example::Airport)
#<V[3] YYZ, Toronto>       #<V[2] SFO, San Francisco> #<V[1] LGA, New York>      #<V[0] LAX, Los Angeles>  
Total: 4
#<GraphV -> V>
```

What just happened?

 * `g.v(Example::Airport)` returns (a route of) all vertices, wrapped in an `Example::Airport` extension.
 * The `Example::Airport::Vertex` module contains a method called `display_name`.    
   This method is used by Pacer to print vertices to the console.

In the example above, we extended the functionality of vertices by
 1. Defining methods inside the `Example::Airport::Vertex` module.
 2. Wrapping our vertices in the `Example::Airport` module/extension.

In the next example, we will extend the functionality of routes (i.e. collections) of vertices.

```ruby
irb(main):213:0> g.v(Example::Airport, {code: 'LGA'}).departures()
#<E[5]:1-flies_to-3> #<E[4]:1-flies_to-0>
Total: 2
#<GraphV -> V-Property(Example::Airport, code=="LGA") -> outE>

irb(main):214:0> g.v(Example::Airport, {code: 'SFO'}).arrivals()
#<E[9]:0-flies_to-2> #<E[8]:0-flies_to-2>
Total: 2
#<GraphV -> V-Property(Example::Airport, code=="SFO") -> inE>
```

Let's look at the example above in more details:
 * `g.v(Example::Airport, {code: 'LGA'})` gives us back a route of vertices.     
 * The vertices in the route are filtered, based on their `code` property, and wrapped in the `Example::Airport` extension.
 * Our `Example::Airport::Route` module defines the methods `arrivals` and `departures`.
 * This allows us to call the `arrivals` and `departures` methods on any route (of vertices that are) extended by `Example::Airport`.

So, this time, we extended the functionality of routes by
 1. Defining methods inside the `Example::Airport::Route` module.
 2. Wrapping our vertices in the `Example::Airport` module/extension.

### Filtering based on extension

What if our graph contains vertices that do not represent airports?      
When we ask for vertices wrapped in the `Example::Airport` extension, we want to get only vertices that actually represent airports.

We can achieve that by defining the `route_conditions` method in the `Example::Airport` module, as follows:
```ruby
def self.route_conditions(graph)
    {type: 'airport'}
end
```

This method tells Pacer that, only elements whose `type` property is `airport` can be wrapped in the `Example::Airport` extension. When we run `g.v(Example::Airport)`, vertices that do not have a `type` property whose value is `airport` will not be included in the result.

Let's see it in action.

```ruby
irb(main):237:0> g.v(Example::Airport)
#<V[3] YYZ, Toronto>       #<V[2] SFO, San Francisco> #<V[1] LGA, New York>      #<V[0] LAX, Los Angeles>  
Total: 4
#<GraphV -> V>

irb(main):238:0> g.create_vertex({foo: 'bar'})
#<V[10]>

irb(main):241:0> g.v(Example::Airport)
#<V[3] YYZ, Toronto>       #<V[2] SFO, San Francisco> #<V[1] LGA, New York>      #<V[0] LAX, Los Angeles>  
Total: 4
#<GraphV -> V-Property(Example::Airport)>

irb(main):242:0> g.v()
#<V[3]>  #<V[2]>  #<V[10]> #<V[1]>  #<V[0]> 
Total: 5
#<GraphV>
```

### Extending Edges


Similarly to the way we extend vertices, we can also extend edges.     
Let's update `example.rb` to contain the following code:
```ruby
module Example

	module Airport

		def self.route_conditions(graph)
			{type: 'airport'}
		end


		module Vertex

			def display_name
				"#{self[:code]}, #{self[:city]}"
			end

		end


		module Route

			def departures
				out_e(Flight)
			end

			def arrivals
				in_e((Flight)
			end
		
		end


	end


	module Flight

		def self.route_conditions(graph)
			:flies_to
		end


		module Edge

			def display_name
				"#{self[:airline]} flight from #{from[:code]} to #{to[:code]}"
			end

			def from
				out_vertex(Airport)
			end

			def to
				in_vertex(Airport)
			end

		end

	end
end
```

Let's see it in action.

```ruby
irb(main):248:0> load('path/to/example.rb')

irb(main):249:0> g.e(Example::Flight)
#<E[7]:Delta flight from LAX to YYZ>             #<E[6]:Air Canada flight from YYZ to LGA>        #<E[5]:Air Canada flight from LGA to YYZ>       
#<E[4]:Delta flight from LGA to LAX>             #<E[9]:American Airlines flight from LAX to SFO> #<E[8]:WestJet flight from LAX to SFO>          
Total: 6
#<GraphE -> E>
```

### Elements vs. Routes

The following example emphasizes the difference between an individual element (vertex or edge), and a route (a collections of elements).

```ruby
irb(main):254:0> g.e(Example::Flight, {airline: 'Delta'}).from
NoMethodError: #<E[7]:Delta flight from LAX to YYZ> #<E[4]:Delta flight from LGA to LAX>
Total: 2
undefined method `from' for #<#<Class:0x1257225>:0x5565a1>

irb(main):255:0> g.e(Example::Flight, {airline: 'Delta'}).first.from
#<V[0] LAX, Los Angeles>
```

We have only defined the `from` method for individual edges, not for routes of edges.
Therefore, the first command above resulted in an error.

Let's change that and add the following code to the `Example::Flight` module:
```ruby
module Route

    def from
        out_v(Airport)
    end

    def to
        in_v(Airport)
    end

end
```

Reload the code in the IRB, and give it a try.

```ruby
irb(main):031:0> g.e(Example::Flight, {airline: 'Delta'}).from.uniq
#<V[0] LAX, Los Angeles> #<V[1] LGA, New York>   
Total: 2
#<GraphE -> E-Property(:flies_to, Example::Flight, airline=="Delta") -> outV -> V-Property(Example::Airport) -> uniq>

irb(main):032:0> g.e(Example::Flight, {airline: 'Delta'}).to.uniq
#<V[3] YYZ, Toronto>     #<V[0] LAX, Los Angeles>
Total: 2
#<GraphE -> E-Property(:flies_to, Example::Flight, airline=="Delta") -> inV -> V-Property(Example::Airport) -> uniq>
```

The queries above find all airports that Delta flies from/to.

### Simplifying Complex Traversals

Extensions allow you to define a complex query as an extension method.
By doing so, you essentially extend the vocabulary of Pacer with a domain-specific vocabulary.

This concept allows you to focus on your domain problem, without thinking about the implementation details 
of complex graph algorithms. 

Let's see an example. We will define the following method in `Example::Airport::Route` module:

```ruby
def reachable_airports(max_hops)
    self.loop { |r| r.departures.to }.while { |e, depth, path| if depth <= max_hops; :emit_and_loop; end }.uniq
end
```

The method above returns airports that are reachable by taking at most `max_hops` flights.     
Although the implementation is slightly complex, once we have implemented the method, we never have to think about it again.

```ruby
irb(main):277:0> g.v(Example::Airport, {code: 'LGA'}).reachable_airports(0)
#<V[1] LGA, New York>
Total: 1
#<GraphV -> V-Property(Example::Airport, code=="LGA") -> V-Loop(#<V -> outE(:flies_to) -> E -> inV -> V-Property(Example::Airport)>) -> uniq>

irb(main):278:0> g.v(Example::Airport, {code: 'LGA'}).reachable_airports(1)
#<V[1] LGA, New York>    #<V[3] YYZ, Toronto>     #<V[0] LAX, Los Angeles>
Total: 3
#<GraphV -> V-Property(Example::Airport, code=="LGA") -> V-Loop(#<V -> outE(:flies_to) -> E -> inV -> V-Property(Example::Airport)>) -> uniq>

irb(main):279:0> g.v(Example::Airport, {code: 'LGA'}).reachable_airports(2)
#<V[1] LGA, New York>      #<V[3] YYZ, Toronto>       #<V[0] LAX, Los Angeles>   #<V[2] SFO, San Francisco>
Total: 4
#<GraphV -> V-Property(Example::Airport, code=="LGA") -> V-Loop(#<V -> outE(:flies_to) -> E -> inV -> V-Property(Example::Airport)>) -> uniq>
```

We don't need to think of breadth/depth first search algorithms. 
Instead, we use a vocabulary that is specific to our domain, and ask for reachable airport.

### Multiple Extensions

We can wrap a graph element with multiple extensions.     
To see an example, let's create the following extension in our `Example` module:
```ruby
module A

    # Only elements whose `code` property is either `LGA` or `LAX` can be wrapped with this extension
    def self.route_conditions(graph)
        {code: Set['LGA', 'LAX']}
    end

    module Route
	def f()
	    "Dummy method f()"
	end
    end
end
```

Now, let's use our extension, `A`, in the IRB:
```ruby
irb(main):100:0> g.v(Example::A,Example::Airport)
#<V[1] LGA, New York>    #<V[0] LAX, Los Angeles>
Total: 2
#<GraphV -> V-Property(Example::A, Example::Airport)>

irb(main):101:0> g.v(Example::A,Example::Airport).f()
"Dummy method f()"
```

The example above shows us that:
 * Only vertices that can wrapped by _both_ `Example::A` and `Example::Airport` are included in the result. 
 * The resulting route is extended with the functionality of both `Example::A` and `Example::Airport`.


### Summary

This is a good place to stop, summarize and add a few notes:
 * We can extend the functionality vertices, edges and routes with arbitrary modules, known as extensions.
 * We can also define custom filtering criteria for each extension we create.
 * We can extend Pacer's vocabulary with a domain-specific vocabulary, by defining complex queries in extension methods.
 * We can extend elements with multiple extensions.


### Full Source Code

Here is the full source code for all of the above examples.

```ruby
module Example


	# A convenience function, used for creating and populating the graph for this example
	def self.create_graph()
		g = Pacer.tg()

		lax = g.create_vertex({type: 'airport', code: 'LAX', city: 'Los Angeles'})
		lga = g.create_vertex({type: 'airport', code: 'LGA', city: 'New York'})
		sfo = g.create_vertex({type: 'airport', code: 'SFO', city: 'San Francisco'})
		yyz = g.create_vertex({type: 'airport', code: 'YYZ', city: 'Toronto'})

		lga.add_edges_to(:flies_to, lax, {airline: 'Delta'})
		lga.add_edges_to(:flies_to, yyz, {airline: 'Air Canada'})
		yyz.add_edges_to(:flies_to, lga, {airline: 'Air Canada'})
		lax.add_edges_to(:flies_to, yyz, {airline: 'Delta'})
		lax.add_edges_to(:flies_to, sfo, {airline: 'WestJet'})
		lax.add_edges_to(:flies_to, sfo, {airline: 'American Airlines'})

		return g
	end



	module Airport

		def self.route_conditions(graph)
			{type: 'airport'}
		end


		module Vertex

			def display_name
				"#{self[:code]}, #{self[:city]}"
			end

		end


		module Route

			def departures
				out_e(Flight)
			end

			def arrivals
				in_e(Flight)
			end

			def reachable_airports(max_hops)
				self.loop { |r| r.departures.to }.while { |e, depth, path| if depth <= max_hops; :emit_and_loop; end }.uniq
			end
		
		end

	end




	module Flight

		def self.route_conditions(graph)
			:flies_to
		end


		module Edge

			def display_name
				"#{self[:airline]} flight from #{from[:code]} to #{to[:code]}"
			end

			def from
				out_vertex(Airport)
			end

			def to
				in_vertex(Airport)
			end

		end

		module Route

			def from
				out_v(Airport)
			end

			def to
				in_v(Airport)
			end

		end

	end




	module A

		def self.route_conditions(graph)
			{code: Set['LGA', 'LAX']}
		end

		module Route

			def f()
				"Dummy method f()"
			end

		end
	end


end
```