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

# Find vertices whose 'name' property is either 'Alice' or Bob'
graph.v(name: Set['Alice', 'Bob'])

# Find vertices whose 'name' property is either 'Alice' or Bob', and 'age' is 30
graph.v(name: Set['Alice', 'Bob'], age: 30)

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

### Using `filter`

The following traversal will result in every vertex that have `gender` and `age` properties whose values are `female` and `30`, respectively.

```ruby
g.v(gender: 'female', age: 30)
```

What if we don't want all the vertices in the graph? What if we want to apply the filter to an arbitrary collection of vertices?     
In such cases, we can use the `filter` method:

```ruby
def thirty_years_old_females(people)
	people.filter(gender: 'female', age: 30)
end
```

The `filter` method works just as you'd expect:

 * `filter(foo: 'a')` - Include items whose `foo` property is `a`.
 * `filter(foo: 'a', bar: 'b')` - Include items whose `foo` property is `a` _and_ `bar` property is `b`.
 * `filter(foo: Set['a', 'b'])` - Include items whose `foo` property is either `a` _or_ `b`.
 * `filter(foo: Set['a', 'b'], bar: 'c')` - Include items whose `foo` property is either `a` _or_ `b`, _and_ `bar` property is `c`.

 

### Using `where`

With `where` you can produce more sophisticated conditions against an individual element. The where method uses JRuby's own parser for fast and
robust parsing, but reinterprets the expressions in the where clause to build graph traversals instead of Ruby code. The where method only uses a
subset of Ruby's syntax features, and any unsupported expression will raise an exception. No code may be executed through where statements, and they
also can not be used to modify data (unlike SQL or Cypher).

Usage:

- `where("age = 27")`
- `where("age = :age", age: 27)` always use this with user input to avoid [injection attacks].

> Despite being save from arbitrary code execution or direct modification, a malicious user could still theoretically inject a where statement to
> bypass your security. For instance: `where("user_id == '#{ user_id }'")` could be given the input `' or user_name == 'admin` which would produce the
> statement `where("user_id == '' or user_name == 'admin'")`. Using `where("user_id == :id", id: user_id)` eliminates that risk.

[injection attacks]: http://pic.dhe.ibm.com/infocenter/sprotect/v2r8m0/index.jsp?topic=%2Fcom.ibm.ips.doc%2Fconcepts%2Fwap_injection_attacks.htm

The following pieces of Ruby syntax are valid in a where clause:

```ruby
< > <= >= == !=       # comparisons
=                     # used as a comparison where syntactically allowed
and or not && || !    # boolean logic
+ - * / %             # simple mathematical expressions
( )                   # expression grouping
:symbol               # symbols are replaced by user values
123 123.45            # numeric constants
"abc" 'abc'           # string constants
true false nil [] {}  # boolean, nil, array, or hash constants
```


### Using `filter` with a block of code

So far, we have seen two types of filtering:

 * Using `filter` - Fast, but limited. The filtering condition is limited to exact property matches, logical-AND and logical-OR.
 * Using `where` - Not as fast (but still fast), but more expressive.

 The `where` statement is fairly expressive, but it is still somewhat limited. To get full expressiveness, you can filter items using a block of Ruby code. This is the most powerful, but also the most expensive (in terms of performance), way of filtering.

 Usage:

- `filter { |element| }` same as select
- `select { |element| }` keep elements when the block result is [truthy].
- `reject { |element| }` eliminate elements when the block result is [truthy].

Example:

```ruby
graph.v.filter { |v| v[:name] == v[:name].reverse } # find palindromic names.
```

> Filtering with a block of code is noticeably slower than the previous two methods, because it has to go through Pacer's element wrapping process. Unlike the other two methods, which are executed in pure Java.     
>   filtering large collections could be several times slower. For smaller collections the impact is
negligible, however.


## Filter items `random`ly

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
 

_Note:_ If our collection is large, we can expect `random(0.2)` to emit 20% of the items in the collection (aka [Law of large numbers](http://en.wikipedia.org/wiki/Law_of_large_numbers) ).


## `lookahead`

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

### `neg_lookahead`

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

