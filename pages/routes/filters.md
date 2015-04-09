---
title: Filters
permalink: /routes-filters/
---


## Basics Filtering

Vertex and edge routes can be filtered based on properties value(s).

```ruby
# Find vertices whose 'name' property has value 'Bob'
graph.v(name: 'Bob')

# Find edges whose 'foo' property has value 'bar'
graph.e(foo: 'bar')
```

Edge routes can also be filtered by edge label.

```ruby
# Find edges whose label is 'related_to'
graph.e(:related_to)

# Filter by label and property
g.e(:flies_to, airline: 'Delta')

```

Combining basic filtering methods, allow us to define meaningful traversals.
For example, we can define the following routes in a social network graph.

```ruby
# Find followers of users that Bob follows
graph.v(type: 'user', name: 'Bob').out_e(:follows).in_v(type: 'user').in_e(:follows).out_v(type: 'user')
```


## Random Filtering

`random` filters out items randomly. It is useful for random sampling, as well as generating random walks through the graph.

The `random` method takes a single numeric argument. 
The argument is the probability of an item being emitted (i.e. not filtered). 


```ruby
# Each item will be included in the result with probability 0.2
g.v.random(0.2)

# If the argument is greater than 1, the probability is its reciprocal.
# For example, included each item with probability of 1/4 = 0.25
g.v.random(4)

# The following examples are fairly useless:
g.v.random(1)  # Include all items
g.v.random(0)  # Exclude all items 

# If the argument is negative, it is treated as 0 (and all items are excluded from the result). 
```
 

_Note:_ If our collection is large, we can expect `random(0.2)` to emit 20% of the items in the collection (aka [Law of large numbersw](http://en.wikipedia.org/wiki/Law_of_large_numbers)
.


## Lookahead

The `lookahead` filter is extremely useful - It allows us to filter items based on a walk through the graph.

For example, in a social network, we may want a filter that gets a collection of users (i.e. vertices), and emits only those users that are followed by more than 1000 people.

The following diagram explains how a lookahead filters each incoming item:

![Lookahead diagram]({{site.baseurl}}/images/lookahead_diagram.png) 

In code, lookaheads can be used as follows:

 * `lookahead(min: 2, max: 5) {|v| v.out_e}` - Keeps vertices that have between 2 to 5 outgoing edges.
 * `lookahead(min: 10) {|v| v.out_e}` - Keeps vertices with at least 10 outgoing edges.
 * `lookahead(max: 10) {|v| v.out_e}` - Keeps vertices with at most 10 outgoing edges.
 * `lookahead {|v| v.out_e}` - Keeps vertices with at least 1 outgoing edge (equivalent to `lookahead(min: 1)`.

Notice that the side-chain traversal (i.e. the block of code) can as complex as you need it to be. Here are a few examples:

```ruby
# Get all flights that land in Toronto
r = g.e(:flies_to).lookahead {|flight| flight.in_v(city: 'Toronto')}
# Or the airlines that operate such flights
g.e(:flies_to).lookahead {|flight| flight.in_v(city: 'Toronto')} [:airline].uniq

# Get popular users in a social network
g.v(type: user).lookahead(min: 1000) {|u| u.in_e(:follows)}
```

### A note on efficiency

Lookaheads are efficient, they do as much work as needed, but no more than that. That is, the side-chain traversals of `lookahead(min:10)` will stop as soon as 10 items are found. Similarly, the side-chain traversal of `lookahead(max: 3)` will stop as soon as it finds 4 items.

### Negative lookaheads

The `neg_lookahead` filter (negative lookahead) excludes items whose side-chain traversal contains at least one item. Negative lookaheads work just like regular lookaheads (i.e. they accept a `min` and `max` argument), but, in terms of coding style, we recommend to only use them when you need to "reverse" a filter.

For example, we can define a 'not_popular' filter, based on a `popular` filter:

```ruby
def popular(users)
    users.lookahead(min: 1000) {|u| u.in_e(:follows)}
end

def not_popular(users)
    # Each user that is included in the popular results, will be excluded by neg_lookahead
    users.neg_lookahead {|u| u.popular}
end
```

