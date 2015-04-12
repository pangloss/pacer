---
title: Traversals
permalink: /routes-traversals/
---

In addition to the basic traversal methods (following edges and/or vertices), 
Pacer routes have a few convenient methods that allow you to easily build more complex traversals.


## `branch`

Let's continue with our simple graph, containing airports and flights.
Now, suppose we want to find all cities we can reach by taking __at most__ two flights from La Guardia Airport.    

Essentially, what we want to do is:

```ruby
# Find the vertex that corresponds to La Guardia airport
v = g.v(airport: 'LGA')

one_flight  = v.out_e.in_v[:city]
two_flights = v.out_e.in_v.out_e.in_v[:city]

# Take the union of the two routes, one_flight and two_flights, somehow ...
```
 
When we want to take the union of two (or more) routes, we use `branch`. 
The diagram below describes how a branch route works.


![Branch diagram]({{site.baseurl}}/images/branch_diagram.png) 

Usage:

```ruby
  branch { |route| }.branch { |route| }.merge
```

Example:

```ruby
def at_most_two_flights_away(v)
	v.out_e.in_v.branch do |airports| 
    	    airports[:city]
	    end.branch do |airports| 
	        airports.out_e.in_v[:city]
	    end.merge
end
```

Let's look at this traversal more closely:
 * `v.out_e.in_v` is a route of vertices - All airports that are one flight away from La Guardia.
 * Our first branch, returns (a route containing) the `city` of each airport.
 * Out second branch, traverses to airports that are an additional flight away, using `airports.out_e.in_v`, and gets the `city` property.
 * We finish by merging the two traversals.


  > _Note:_ Calling `merge` is not strictly necessary, but is a good idea.    
  > For example, if you try to do two 2-way branches in a row, without a merge statement between them, you will accidentally produce one 4-way branch. This is an easy mistake to make if you build the branches with helper methods.


### `merge` vs. `merge_exhaustive`

Pacer provides two different ways to merge the items from branches. The difference between the two methods is the order of the output items.

 * `merge` (default) uses a round-robin strategy.
 * `merge_exhaustive` completely exhaust each branch in order, before starting on the next one.


## `identity`

Let's take another look at the following code example:

```ruby
def at_most_two_flights_away(v)
	v.out_e.in_v.branch do |airports| 
    	    airports[:city]
	    end.branch do |airports| 
	        airports.out_e.in_v[:city]
	    end.merge
end
```

If you hate repeated code as much as I do, you may want to get rid of the repeated `[:city]`, and write the code as:


```ruby
def at_most_two_flights_away(v)
	v.out_e.in_v.branch do |airports| 
		airports
	end.branch do |airports| 
		airports.out_e.in_v
	end.merge[:city]
end
```

If you try running the code above, __you will get an error__.     
This is because each `branch` block is required to build a route (or, if you look at [the diagram above](#branch), "all of the pipes must exist").

The `identity` route is useful for situations like this. We can fix the above code as follows:


```ruby
def at_most_two_flights_away(v)
	v.out_e.in_v.branch do |airports| 
		airports.identity
	end.branch do |airports| 
		airports.out_e.in_v
	end.merge[:city]
end
```

## `loop`

Looping is a fairly basic concept in programming. In Pacer, and the world of graph databases in general, 
looping means _"repeating traversal patterns"_. For example:

 * Starting from an airport, look for a departing flight, get its destination airports, and repeat.
 * In an ancestry tree, go two levels up (to your grandparents), then two levels down (to all of their grandchildren), repeat this process.

The diagram below describes how a `loop`/`while` route works:

![Loop diagram]({{site.baseurl}}/images/loop_diagram.png) 


Unlike most routes, loop requires 2 blocks:

 * `loop` block, containing some arbitrary traversal that will be repeated. 
 * `while` block that determines whether to feed an item back to the `loop` block, as well as whether to emit the item (i.e. include the item in the output).

Usage:

- `loop { |route| arbitrary_steps(route) }.while { |element, depth| }`
- `loop { |route| arbitrary_steps(route) }.while { |element, depth, path| }`


The `while` block controls the loop by returning either `:loop`, `:emit`, `:loop_and_emit`, or `nil`.

Some elements passed to the while block will be source elements. They have a depth of 0, and have never run through the loop traversal at all.

- `:loop` = do not emit the element into the results of this traversal, but feed it back through the loop.
- `:emit` = emit the element into the results of this traversal, but do not feed it back through the loop.
- `:loop_and_emit` = both emit the element and feed it back through the loop.
- `:emit_and_loop` = same as `:loop_and_emit` (because I could never remember which one to use).
- `nil` or `false` = don't emit this element and don't feed it back through the loop.

Example:

```ruby
def reachable_via_at_most_n_flights(airport, n)
	airport.loop do |r| 
		r.out_e.in_v
	end.while do |airport, depth| 
		if depth == 0
			:loop
		elsif depth <= n
			:loop_and_emit
		else
			false
	end
end
```

