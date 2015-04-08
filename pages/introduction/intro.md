---
title: What is Pacer?
permalink: /intro/
toc: false
---

Pacer is graph traversal library, written in [JRuby](http://jruby.org/).

 * Enables very expressive graph traversals.
 * Supports all of the major graph databases, including [OrientDB](http://orientdb.com), [Neo4j](http://neo4j.org)
and [Dex](http://www.sparsity-technologies.com/dex), thanks to the
[Tinkerpop](http://tinkerpop.com) graphdb stack. 
 * Comes with a very convenient in-memory graph called [TinkerGraph](https://github.com/tinkerpop/blueprints/wiki/TinkerGraph).
 * Traverses the graphs using very fast and memory efficient stream processing. 
 * All processing is done in pure Java, so when it comes the usual Ruby expressiveness vs. speed problem, you can have your cake and eat it too. It's very fast!


## Pacer in 60 seconds

In order to provide efficient graph traversal, Pacer chains [Pipes](http://pipes.tinkerpop.com) together and wraps them in [Pacer Routes](Routes).

![Diagram 2]({{site.baseurl}}/images/PacerHome_img2.png)

<br />

In order to provide developer-friendly API, [Pacer Extensions](Pacer-extensions) allow you to extend graph elements with arbitrary functionality.

![Diagram 3]({{site.baseurl}}/images/PacerHome_img3.png)

<br />


With these two concepts, Pacer allows you to use your own domain-specific language to get efficient graph queries that look like this ...

```ruby
# Trending posts that were liked by your friends
user_vertex.friends.liked.posts.trending

# Faulty hard-drive in some region of your data center
data_center.region('A').hard_drives.faulty

# Number of traffic lights on your drive to the office
home.directions_to('Queen & Spadina').traffic_lights.count
```

## Questions or need help?

This wiki is the main source of documentation for **developers** working with Pacer.

[xnlogic] makes a graph database application framework built with Pacer technology.      
If you think a graph database is appropriate for your problem space, the team at XN can provide you the help you need. The XN framework has extremely powerful data modelling capabilities, tight security and
allows you to deliver an incredible domain-specific API to your data with ease.

Pacer also has a [mailing list] where you can go for community support to get you past whatever problems you encounter.

[mailing list]: https://groups.google.com/forum/?hl=en#!forum/pacer-users

Finally, there are great meetup groups like [GraphTO] in Toronto which meets periodically, and conferences like [GraphConnect], held in San Francisco
and other American cities.

[GraphConnect]: http://www.graphconnect.com/
[GraphTO]: http://www.meetup.com/graphTO/


[xnlogic]: http://xnlogic.com
[neo4j]: http://www.neotechnology.com
[JRuby]: http://jruby.org
[ml]: https://groups.google.com/forum/#!forum/pacer-users
