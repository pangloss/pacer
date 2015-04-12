---
title: Edge Extensions
permalink: /edge-extensions/
---

Edges can be extended similarly to the way we extend vertices.     
Let's see a quick example...


## Create an extension

```ruby
module Flight

    module Edge

        def display_name
            "#{self[:airline]} flight from #{self.origin_city.first} to #{self.dest_city.first}."
        end
        
    end


    module Route

        def origin_city
            self.out_v[:city]
        end

        def dest_city
            self.in_v[:city]
        end

    end

end
```

Before we test this code in the IRB, there are a few points we should mention:

 - Methods that extend a single item are defined in the `Edge` sub-module.
 - A route of edges is extended by `Route` methods, and a single edge is extended by both, `Route` and `Edge` methods.
 - Inside an edge method (for example, `display_name`), we can use other edge and route methods. For example, `origin_city` and `dest_city`.
 - The `origin_city` and `dest_city` methods return a _route of strings_.     
   Therefore, when we use them in `display_name`, we call `first` in order to get the actual string object from the route.
 - The `display_name` method works the same as for vertices - If it exists, it will be used for printing item to the console.

## Use the extension

Just as before, we can extend routes and edges:

```ruby
jruby-1.7.19 :227 > flights = g.e(Flight)
#<E[7]:Delta flight from Los Angeles to Toronto.>     
#<E[6]:Air Canada flight from Toronto to New York.>                
#<E[5]:Air Canada flight from New York to Toronto.>   
#<E[8]:WestJet flight from Los Angeles to San Francisco.>
#<E[4]:Delta flight from New York to Los Angeles.>    
#<E[9]:American Airlines flight from Los Angeles to San Francisco.>             
Total: 6

jruby-1.7.19 :228 > flight = flights.first
 => #<E[7]:Delta flight from Los Angeles to Toronto.> 
```

We can now use our extension methods

```ruby
jruby-1.7.19 :229 > flights.origin_city.uniq
"Los Angeles" "Toronto"     "New York"   
Total: 3

jruby-1.7.19 :230 > flight.dest_city
"Toronto"
Total: 1
```

