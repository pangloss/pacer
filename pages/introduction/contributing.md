---
title: Contributing to Pacer
permalink: /contributing/
---


Contributions to both Pacer and to this wiki are both very welcome.

If you find a bug, please [report an issue here](https://github.com/pangloss/pacer/issues).

If you are considering contributing a new feature to Pacer, please start by creating an issue describing the feature you have in mind, or by starting a new thread in the [mailing list].     
Features and feature ideas are welcome, but will only be accepted if they fit with the overall vision of
Pacer.

## Developing Locally

After forking a local copy of the [Pacer repo](https://github.com/pangloss/pacer), you can easily start hacking at Pacer.

 * Make your changes.
 * `cd` to the root of the local repo.
 * Run `bundle`.

In order to quickly test your changes in the IRB, run the following command (from the root of the repo):
```
bundle exec irb -r pacer
```
Notice that the IRB will start with `Pacer` already loaded (so there is no need to require it).    
If you make changes to the code, you can reload pacer with the following command:
```ruby
Pacer.reload!
```

In order to run the test suite on your local changes, use the following command:
```
bundle exec autotest
```



## Plugins

Pacer also has a strong ability to support pluggable behavior and several plugins exist for Pacer for a variety of applications, from 
[xml parsing](https://github.com/pangloss/pacer-xml), to [parallelizing traversals](https://github.com/pangloss/pacer-parallel).

## Graph DB support

GraphDB support is also added via plugins. See [pangloss/pacer-neo4j](https://github.com/pangloss/pacer-neo4j) or [bloudermilk/pacer-titan](https://github.com/bloudermilk/pacer-titan) for instance.

[mailing list]: https://groups.google.com/forum/?hl=en#!forum/pacer-users
