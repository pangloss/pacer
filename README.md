# Pacer
[![Coverage Status](https://img.shields.io/coveralls/pangloss/pacer.svg)](https://coveralls.io/r/pangloss/pacer) [![Build Status](https://travis-ci.org/pangloss/pacer.svg)](https://travis-ci.org/pangloss/pacer)  [![Code Climate](https://codeclimate.com/github/pangloss/pacer/badges/gpa.svg)](https://codeclimate.com/github/pangloss/pacer)

Pacer is a JRuby library that enables very expressive graph traversals.

It currently supports all of the major graph databases including [OrientDB](http://orientdb.com), [Neo4j](http://neo4j.org)
and [Dex](http://www.sparsity-technologies.com/dex) thanks to the
[Tinkerpop](http://tinkerpop.com) graphdb stack. Plus there's a very
convenient in-memory graph called TinkerGraph which is part of
[Blueprints](http://blueprints.tinkerpop.com).

Pacer allows you to create, modify and traverse graphs using very fast
and memory efficient stream processing thanks to the very cool
[Pipes](http://pipes.tinkerpop.com) library. That also means that almost
all processing is done in pure Java, so when it comes the usual Ruby
expressiveness vs. speed problem, you can have your cake and eat it too,
it's very fast!

## Mailing List

Pacer has a [google group](http://groups.google.com/group/pacer-users?lnk=gcimv)! Join and feel free to ask questions and discuss about Pacer or graphs in general.

## Documentation

Check out the [wiki](https://github.com/pangloss/pacer/wiki) for detailed explanations of many of Pacer's features. Please contribute to it or open issues against it if there is anything missing that you want to see.

Pacer is also documented with a comprehensive RSpec test suite and with a
thorough YARD documentation. [Dig in!](http://www.rubydoc.info/github/pangloss/pacer/master)

If you like, you can also use the documentation locally via

```
  gem install yard
  yard server
```

## JRuby 1.7 Required

As of Pacer 1.0.0, [JRuby](http://jruby.org/) 1.7 is required because it is both faster and
fixes some problems that I previously had to work around in Pacer.

The easiest way (ie. the way I do it) to get the most recent version of
JRuby is to use [RVM](https://rvm.io/)

## Installation

The easiest way to get Pacer is `gem install pacer`.

If you want to hack on Pacer, you'll need to have
[maven](http://maven.apache.org/) installed (I recommend `brew install
maven`), then use `rake jar` to set up maven's pom.xml file and run the
maven build script. Then `rake gemfile_devel` to set up a default
Gemfile that you can customize as needed to include dependencies
to the various pacer-... graphs you want the test suite to run against.

## Graph Database Support

The Tinkerpop suite supports a number of graph data stores. They are all
compatible with Pacer, but I have not yet implemented the simple
adapters Pacer needs to use them yet. Here is the list of what's
supported so far:

| Graph                                          | Info                                     | Gem Required              | Gem address                                                     |
|------------------------------------------------|------------------------------------------|---------------------------|-----------------------------------------------------------------|
| TinkerGraph                                    | In-memory graph db. Included with Pacer. |                           |                                                                 |
| [OrientDB](http://orientdb.com)                | A powerful and feature rich graph / document hybrid database.           | `gem install --pre pacer-orient` | [pangloss/pacer-orient](https://github.com/pangloss/pacer-orient) |
| [Neo4J](http://neo4j.org)                      | The industry-leading graph db.           | `gem install pacer-neo4j` | [pangloss/pacer-neo4j](https://github.com/pangloss/pacer-neo4j) |
| [Dex](http://sparsity-technologies.com)        | A very fast, relatively new graph db.    | `gem install pacer-dex`   | [pangloss/pacer-dex](https://github.com/pangloss/pacer-dex)     |
| [Titan](http://thinkaurelius.github.io/titan/) | Built on top of a pluggable nosql backend store | `gem install pacer-titan` | [pacer-titan](https://github.com/mrbotch/pacer-titan)           |



You can run any or all of the above graph databases. Pacer supports
running them simultaneuosly and even supports having many of any given
type open at once.

### Using Pacer with Neo4j

All you need is the [pacer-neo4j](https://github.com/pangloss/pacer-neo4j) gem.

```ruby
    require 'pacer-neo4j'
    graph = Pacer.neo4j("path/to/graph")
```

See the gem repository for more details on Neo4j-specific features and functionality.

#### (optional) Interoperation with the neo4j gem

Pacer can work together with other Ruby GraphDB libraries, too. The
first functioning example is with theo neo4j gem. Hopefully more will
follow soon as I find out about them or get requests to support them.

To use Pacer together with the neo4j gem, get your Pacer graph instance
as follows:

```ruby
    require 'neo4j'
    require 'pacer-neo4j'
    # start neo4j via the external gem rather than using pacer-neo4j
    Neo4j.db.start
    graph = Pacer.neo4j(Neo4j.db.graph)
```

After that, you can continue to use the graph as normal with *both*
gems. Any update that's committed with one gem will be visible
immediately to the other because they are now both pointing to the same
Java graphdb instance.

### A note on safely exiting

Some databases need to be shutdown cleanly when the program exits. You
can shut a database down anytime by calling `graph.shutdown`, but you
don't need to worry about it much. Pacer uses Ruby's `at_exit` hook to
automatically shut down all open databases!

## Example traversals

Friend recommendation algorithm expressed in basic traversal functions:

```ruby
    friends = person.out_e(:friend).in_v(:type => 'person')
    friends.out_e(:friend).in_v(:type => 'person').except(friends).except(person).most_frequent(0...10)
```

or using Pacer's route extensions to create your own query methods:

```ruby
    person.friends.friends.except(person.friends).except(person).most_frequent(0...10)
```

or to take it one step further:

```ruby
    person.recommended_friends
```

## Create and populate a graph

To get started, you need to know just a few methods. First, open up a graph (if one doesn't exist it will be automatically created) and add some vertices to it:

```ruby
    dex = Pacer.dex '/tmp/dex_demo'
    dex.transaction do
      pangloss = dex.create_vertex :name => 'pangloss', :type => 'user'
      okram = dex.create_vertex :name => 'okram', :type => 'user'
      group = dex.create_vertex :name => 'Tinkerpop', :type => 'group'
    end
```

Now, let's see what we've got:

```ruby
    dex.v
```

produces:

```ruby
    #<V[1024]> #<V[1025]> #<V[1026]>
    Total: 3
    => #<GraphV>
```

There are our vertices. Let's look their properties:

```ruby
    dex.v.properties

    {"name"=>"pangloss", "type"=>"user"} {"name"=>"okram", "type"=>"user"}
    {"name"=>"Tinkerpop", "type"=>"group"}
    Total: 3
    => #<GraphV -> Obj-Map>
```

Now let's put an edge between them:

```ruby
    dex.transaction do
      dex.create_edge okram, pangloss, :inspired
    end
    => #<E[2048]:1025-inspired-1024>
```

That's great for creating an edge but what if I've got lots to create? Try this method instead which can add edges to the cross product of all vertices in one route with all vertices in the other:

```ruby
    dex.transaction do
      group.add_edges_to :member, dex.v(:type => 'user')
    end

    #<E[4097]:1026-member-1024> #<E[4098]:1026-member-1025>
    Total: 2
    => #<Obj 2 ids -> lookup>
```

There is plenty more to see as well! Please dig into the code and the spec suite to find loads of examples and edge cases. And if you think of a case that I've missed, I'll greatly appreciate your contributions!

## Design Philosophy

I want Pacer and its ecosystem to become a repository for real implementations of ideas, best practices and techniques for streaming data manipulation. I've got lots of ideas that I'd like to add, and although Pacer seems to be quite rock solid right now -- and I am using it in limited production environments -- it is still in flux. If we find a better way to do something, we're going to do it that way even if that means breaking changes from one release to another.

Once Pacer matures further, a decision will be made to 'lock it down' at least a little more, hopefully there will be a community in place by then to help determine the right time for that to happen!

## Pluggable Architecture

Pacer is meant to be extensible and is built on a very modular architecture. Nearly every chainable route method is actually implemented in an independent module that is plugged into the route only when it's in use. That allows great flexibility in adding methods to routes without clogging up the method namespace. It also makes it natural to make pacer plugin gems.

There are lots of examples of route extensions right inside Pacer. Have a look at the [lib/pacer/filter](https://github.com/pangloss/pacer/tree/develop/lib/pacer/filter), [side_effect](https://github.com/pangloss/pacer/tree/develop/lib/pacer/side_effect) and [transform](https://github.com/pangloss/pacer/tree/develop/lib/pacer/transform) folders to see the modules that are built into Pacer. They vary widely in complexity, so take a look around.

If you want to add a traversal technique to Pacer, you can fork Pacer and send me a pull request or just create your own pacer-&lt;feature name&gt; plugin! To see how to build your own Pacer plugin, see my [example pacer-bloomfilter plugin](https://github.com/pangloss/pacer-bloomfilter) which also has a readme file that goes into considerable detail on the process of creating plugins and provides some additional usage examples as well.

As a side note, don't worry about any magic happening behind the scenes to discover or automatically load pacer plugins, there is none of that! If you want to use a pacer plugin, treat it like any other gem, add it to your Gemfile (if that's what you use) and <code>require</code> the gem as normal if you need it.

## Gremlin

If you're already familiar with [Gremlin](http://gremlin.tinkerpop.com), please look at my [Introducing Pacer](http://ofallpossibleworlds.wordpress.com/2010/12/19/introducing-pacer) post for a simple introduction and explanation of how Pacer is at once similar to and quite different from Gremlin, the project that inspired it. That post is a little out of date at this point since it refers to the original version of Gremlin. Groovy Gremlin is the latest version, inspired in turn by Pacer!

A great introduction to the underlying concept of pipes can be found in Marko Rodriguez' post [On the Nature of Pipes](http://markorodriguez.com/2011/08/03/on-the-nature-of-pipes/)

## Test Coverage

I'm aiming for 100% test coverage in Pacer and am currently nearly there in the core classes, but there is a way to go with the filter, transform and side effect route modules. Open coverage/index.html to see the current state of test coverage. And of course contributions would be much apreciated.

## Style Guide

Please follow Github's [Ruby style guide](https://github.com/styleguide/ruby) when contributing to make your patches more likely to be accepted!

## YourKit Profiler

One of the advantages of building Pacer on JRuby is that we can leverage
the incredible tools that exist in the JVM ecosystem. YourKit is a tool
that I found through glowing recommendation, and has been greatly useful
in profiling the performance of Pacer.

YourKit is kindly supporting the Pacer open source project with its full-featured Java Profiler.
YourKit, LLC is the creator of innovative and intelligent tools for profiling
Java and .NET applications. Take a look at YourKit's leading software products:

<a href="http://www.yourkit.com/java/profiler/index.jsp">YourKit Java Profiler</a> and
<a href="http://www.yourkit.com/.net/profiler/index.jsp">YourKit .NET Profiler</a>.
