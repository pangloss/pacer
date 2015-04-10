---
title: Pacer In 60 Seconds
permalink: /pacer-in-60-sec/
toc: false
---


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
