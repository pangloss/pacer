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

## Documentation

Check out the [Pacer docs](http://pangloss.github.io/pacer/) for detailed explanations of many of Pacer's features. 

Feel free to contribute to it, by submitting a pull-request to the `gh-pages` branch of this repo, or by opening issues.

Pacer is also documented with a comprehensive RSpec test suite and with a
thorough YARD documentation. [Dig in!](http://www.rubydoc.info/github/pangloss/pacer/master)

If you like, you can also use the documentation locally via

```
  gem install yard
  yard server
```

## Installation

Install the dependencies:

 * [JRuby 1.7.x](http://jruby.org/)
   __Recommended:__ Use [RVM](https://rvm.io/) to install and manage all Ruby (and JRuby) versions on your machine.
 * [RubyGems](https://rubygems.org/)

Install Pacer:

`gem install pacer`.

## Graph Database Support

Pacer can work with any Blueprints-enabled graph, such as Neo4j, OrientDB, TinkerGraph and more.

[See the docs](http://pangloss.github.io/pacer/suppoted_graph_databases/) for more details.


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

You can use the [Quick Start guide](http://pangloss.github.io/pacer/quick_start/) to get a feel for how Pacer queries (aka traversals) work.

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
