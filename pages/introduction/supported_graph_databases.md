---
title: Supported Graph Databases
permalink: /suppoted_graph_databases/
toc: false
---


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
running them simultaneously and even supports having many of any given
type open at once.

#### TinkerGraph

Out of the box, Pacer comes with only the simple in-memory **TinkerGraph**, an excellent graph for
testing and for temporary in-memory data. Start a TinkerGraph with:

```ruby
tinkergraph = Pacer.tg
```

#### Neo4j

[Neo4j] is the primary database used by [XN Logic], the team behind Pacer. It's an excellent, reliable and performant graph database that works well
for a variety of use cases, and scales to easily support the largest data sets our customers have hit us with. Once the [pacer-neo4j] gem is
installed, you can start a Neo graph with:

[XN Logic]: http://xnlogic.com

```ruby
require 'pacer-neo4j'
neograph = Pacer.neo4j '/path/to/graph_dir'
```

As of August 2014, Pacer supports Neo4j v1.9 and v2.0. v2.1 support is in development.

#### (optional) Inter-operation with the neo4j gem

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


#### Titan

Pacer has [Titan] support via the `pacer-titan` community contributed gem. Titan is a distributed graph database focussed on supporting extremely
large graphs. Once you've configured your project as required by the [pacer-titan] library, you can start a Titan graph like this:

```ruby
require 'pacer-titan'
titangraph = Pacer.titan 'path/to/titan_config.properties'
```

[Neo4j]: http://www.neotechnologies.com
[pacer-neo4j]: https://github.com/pangloss/pacer-neo4j
[Titan]: http://thinkaurelius.github.io/titan/
[pacer-titan]: https://github.com/mrbotch/pacer-titan

#### Other graphs

Pacer can support [OrientDB] and [Sparksee] (formerly known as Dex) graph databases in addition to RDF graphs and others that I may not be aware of.
The only requirement is that the graph have a [Blueprints] adapter. The `pacer-neo4j` and `pacer-titan` gems add graph-specific functionality on top
of Pacer's built-in capabilities, but any blueprints compatibile graph can easily be used with Pacer with minimal effort.

[OrientDB]: http://www.orientechnologies.com/orientdb/
[Sparksee]: http://www.sparsity-technologies.com/
[Blueprints]: https://github.com/tinkerpop/blueprints/wiki/


### A note on safely exiting

Some databases need to be shutdown cleanly when the program exits. You
can shut a database down anytime by calling `graph.shutdown`, but you
don't need to worry about it much. Pacer uses Ruby's `at_exit` hook to
automatically shut down all open databases!