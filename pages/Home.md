---
title: Pacer Docs
permalink: /home/
toc: false
id: homepage
---

Pacer is graph traversal library, written in [JRuby](http://jruby.org/).

 * Enables very expressive graph traversals.
 * Supports all of the major graph databases, including [OrientDB](http://orientdb.com), [Neo4j](http://neo4j.org)
and [Dex](http://www.sparsity-technologies.com/dex), thanks to the
[Tinkerpop](http://tinkerpop.com) graphdb stack. 
 * Comes with a very convenient in-memory graph called [TinkerGraph](https://github.com/tinkerpop/blueprints/wiki/TinkerGraph).
 * Traverses the graphs using very fast and memory efficient stream processing. 
 * All processing is done in pure Java, so when it comes the usual Ruby expressiveness vs. speed problem, you can have your cake and eat it too. It's very fast!


## Pacer is the easiest

Defining graph traversals using various query languages or traversal APIs is not easy. When I first started out playing with Neo4j and other graph DBs, I could see the insane power but there was a huge disconnect between what I wanted to do and what the existing tools forced me to do. I wanted to think about my queries as moving through the graph, not as an abstract pattern or as a system of gathering and pruning!

Fortunately I wasn't the only one feeling the pain. Together with the smart guys at Tinkerpop, I've built Pacer. Pacer is 100% focussed on doing things the Ruby way, which means it's easy to use and does what you expect.

Pacer is designed to be friendly to play with in IRB (or any other terminal). Its commands are concise and its output is designed for humans. I highly recommend getting to know Pacer by playing with it in the console!


## Pacer is the most powerful

Anything you can do with any other graph query framework can also be done with Pacer. In addition, Pacer's flexibility means that if you want to use features from other libraries, they are easy to fold into Pacer's super simple modular structure. For instance, Neo4j includes some handy graph algorithms which I've wrapped up a simple plugin gem at https://github.com/pangloss/pacer-neo4j-algo . Most of the time you won't need those (in my experience) but they're there in a pinch!


## Pacer is fast

Pacer runs on JRuby, generally the fastest Ruby. In addition, most graph traversal logic runs in pure Java internally, only spitting out your results in the form of nice Ruby objects. That means that when you're trying to get shit done pronto, Pacer's on your side.
