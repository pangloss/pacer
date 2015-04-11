---
title: Traversals
permalink: /routes-traversals/
---

We have already seen the most basic traversal methods: `out_e`, `in_e`, `both_e`, `out_v`, `in_v` and `both_v`. 
Let's see what else we can do:
 
## Getting properties

We get properties from a route the same way we do for a single element. 


### `properties`

Get all properties (of each item in the route). This method returns a route of hash objects.

### `[]`

Get a specific property (of each item in the route). This method returns a route of objects.


> _Note:_ Setting properties is done on an individual vertex, _not_ on a route.


## `limit`, `offset` and `range` 


```ruby
# Get at most 99 items
g.v.limit(99)

# Skip the first 3 items
g.v.offset(3)

# Skip the first 5 items, and get the next (at most) 3 items.
g.v.offset(5).limit(3)
# The command above is identical to
g.v.limit(3).offset(5)
```

The most intuitive use-case of `limit` and `offset` is pagination:

```ruby
page_index     = 0
items_per_page = 100

loop do 
  route = g.v.limit(items_per_page).offset(page_index * items_per_page)
  page_index += 1
  break if route.empty?
end 
``` 

The `range` method is an alternative to combining `limit` and `offset`: 

```ruby
# Get the range of items from index 10 to 100 (including both).
g.v.range(10, 100)
# The route above is equivalent to
g.v.limit(91).offset(10)
```


## `uniq`

Removes duplicates.

Example:

```ruby
jruby-1.7.19 :183 > g.v.out_e.in_v
#<V[3]> #<V[0]> #<V[3]> #<V[2]> #<V[2]>
Total: 5

jruby-1.7.19 :184 > g.v.out_e.in_v.uniq
#<V[3]> #<V[0]> #<V[2]>
Total: 3
```

## `count`

Returns the number of items in the route.

Example:

```ruby
jruby-1.7.19 :272 > g.v.count
 => 4 
```

## `frequencies`

Return a hash, mapping each item to the number of times it occurs in the route.     
For example:

```ruby
jruby-1.7.19 :321 > g.e[:airline]
"Delta"  "Air Canada"  "Delta"  "American Airlines"  "WestJet"          
Total: 5

jruby-1.7.19 :322 > g.e[:airline].frequencies
 => {"Delta"=>2, "Air Canada"=>1, "American Airlines"=>1, "WestJet"=>1} 
```


## `paths`

When a traversal walks through the graph, Pacer can keep track of what it encounters on each step along the way. You can access that with the Paths Route.

For example, in a graph where vertices are airports and edges are flights, we could ask for all cities we can reach by taking exactly two flight from Toronto:

```ruby
g.v(city: 'Toronto').out_e.in_v.out_e.in_v[:city]
```

In my IRB, the output of the above route is:

```
"Toronto"     "Los Angeles"
Total: 2
```

If we want to know the full path from New York to each other city, we can use the `paths` method:

```ruby
g.v(city: 'New York').out_e.in_v.out_e.in_v.paths
```

Which, in my IRB, results in the following output:

```
[#<V[3]>, #<E[6]:3-flight-1>, #<V[1]>, #<E[5]:1-flight-3>, #<V[3]>] 
[#<V[3]>, #<E[6]:3-flight-1>, #<V[1]>, #<E[4]:1-flight-0>, #<V[0]>]
Total: 2
```
 
Each of the path above is an array of alternating vertices and edges.     
Here is what the paths look like in the sample graph I am currently using in my IRB:

```
> _.each {|p| puts("#{p[0][:city]} -#{p[1][:airline]}-> #{p[2][:city]} -#{p[3][:airline]}-> #{p[4][:city]}")}

Toronto -Air Canada-> New York -Air Canada-> Toronto
Toronto -Air Canada-> New York -Delta-> Los Angeles
```


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



