---
title: Extensions 101
permalink: /extensions-101/
---


Pacer extensions allow you to extend vertices and routes with your own Ruby methods.     
If routes are what makes Pacer fast, then extensions are what makes it powerful.     

## How do they work?

### Define an extension

```ruby
module MyExtension

	module Vertex

		def f()
			self.out_e.in_v   # self is a vertex object
		end

	end

	module Route

		def g()
			self.first.out_e.in_v   # self is a route object
		end

	end

end
```

### Use it

```ruby
# The route g.v is extended with MyExtension
g.v(MyExtension)


# Since g.v is a route, it is extended with Route methods
g.v(MyExtension).g


# A single vertex is extended with Vertex methods
g.v(MyExtension).first.f

```

## What are they good for?

Pacer extensions allow you to extend Pacer with your domain specific language.    
They abstract away the details of the underlying graph, and let you build more interesting traversals (i.e. answer more interesting questions).

For example, you can write extensions that will allow you to query a flights database as follows:

```ruby
g.v(Airport, airport: 'LGA').flights_to('LAX').non_stop.morning.on('2015-3-4')
```

Or, search for potential new followers for your tweeter account as follows:

```ruby
# Look at my tweets, then the users who retweeted them, but only those who are not already following me
me.tweets.retweeted_by.not_following(me)
```

The traversal above can be defined as a Vertex method in the extension. This will allow us to do:

```ruby
# Much simpler ...
me.potential_new_followers

# Chain it with other traversals to build complex traversals
me.potential_new_followers.tweets.trending
```



