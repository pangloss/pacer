---
title: More on extensions
permalink: /more-on-extensions/
---

## Multiple extensions

You can wrap a route/vertex/edge in multiple extensions. For example, define the following extensions:

```ruby
module A
	module Vertex
		def display_name
			"I am A"
		end
	end
end

module B
	module Vertex
		def display_name
			"I am B"
		end
	end
end
```

Now, we can use them as follows:

```ruby
jruby-1.7.19 :105 > g.v(A)
#<V[3] I am A> #<V[2] I am A> #<V[1] I am A> #<V[0] I am A>
Total: 4

jruby-1.7.19 :106 > g.v(B)
#<V[3] I am B> #<V[2] I am B> #<V[1] I am B> #<V[0] I am B>
Total: 4

jruby-1.7.19 :107 > g.v(A,B)
#<V[3] I am B> #<V[2] I am B> #<V[1] I am B> #<V[0] I am B>
Total: 4
```

### Overriding

In the example above, we extend the route with `A,B`, and the `display_name` method from `B` overrides the one from `A`.      
The question is, if we extend a route with `B,A`, will `A` override `B`?

```ruby
jruby-1.7.19 :108 > g.v(B,A)
#<V[3] I am B> #<V[2] I am B> #<V[1] I am B> #<V[0] I am B>
Total: 4
```

That's now what we expected. Why didn't `A` override `B`?      

This is because Pacer, in order to be efficient, caches _sets_ of extensions that are used together. 
Once a set of extensions was used to extend a route, the override order for that set is determined.


If you need to change this default behaviour, you can clear the cahce.

#### `Pacer.clear_plugin_cache`

```ruby
# Clear the cache
jruby-1.7.19 :112 > Pacer.clear_plugin_cache

# A overrides B
jruby-1.7.19 :113 > g.v(B,A)
#<V[3] I am A> #<V[2] I am A> #<V[1] I am A> #<V[0] I am A>

# Clear the cache again
jruby-1.7.19 :114 > Pacer.clear_plugin_cache
 
# This time B overrides A
jruby-1.7.19 :115 > g.v(A,B)
#<V[3] I am B> #<V[2] I am B> #<V[1] I am B> #<V[0] I am B>
```


### Filtering

When extending a route with multiple extensions, only items that satisfy __all `route_conditions`__ will be included.

For example, consider the following extensions:

```ruby
module Phone
	def self.route_conditions(graph)
        {type: :phone}
    end
end

module AndroidDevice
	def self.route_conditions(graph)
        {os: :android}
    end
end
```

With the following data:

```ruby
g.create_vertex({type: :phone, os: :android})
g.create_vertex({type: :phone, os: :ios})
g.create_vertex({type: :tablet, os: :android})
g.create_vertex({type: :tablet, os: :ios})
```

In the IRB:

```ruby
# All phones
jruby-1.7.19 :161 > g.v(Phone).properties
{"os"=>:android, "type"=>:phone} {"os"=>:ios, "type"=>:phone}    
Total: 2

# All Android devices
jruby-1.7.19 :162 > g.v(AndroidDevice).properties
{"os"=>:android, "type"=>:phone}  {"os"=>:android, "type"=>:tablet}
Total: 2

# All Android phones
jruby-1.7.19 :163 > g.v(Phone,AndroidDevice).properties
{"os"=>:android, "type"=>:phone}
Total: 1
```



## The `extensions` method

Routes, vertices and edges have an `extensions` method, which returns their extensions as a list of module objects.     
For example:

```ruby
jruby-1.7.19 :188 > g.v(Phone).extensions
 => [Phone] 

jruby-1.7.19 :189 > g.v(Phone,AndroidDevice).extensions
 => [Phone, AndroidDevice]
```

Common usage:

```ruby
def some_method(route)
    if route.extensions.include? Ext1
    	# Do something ...
    elsif route.extensions.include? Ext2
    	# Do something else ...
    else
    	# ...
    end
end
```

  > _Note:_ An extension that doesn't contain any of the `Route`, `Vertex` or `Edge` sub-modules, is considered _irrelevant_ by Pacer.      
  > When calling `extensions` on a single items, irrelevant extensions are dropped from the list. On the other hand, when calling it on a route, they are kept.      

  > This is an edge case, as most extensions define useful methods.
  > That being said, there are cases where as extension do not define any methods, and are used for filtering purposes only.

