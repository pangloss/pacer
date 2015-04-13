---
title: Install
permalink: /install/
---


## Dependencies

 * [JRuby](http://jruby.org/) (currently supporting version 1.7.x)     
   __Recommended:__ Use [RVM](https://rvm.io/) to install and manage all Ruby (and JRuby) versions on your machine.
 * [RubyGems](https://rubygems.org/)

Because Pacer runs on top of JRuby, it runs on _any operating system that can run JRuby_ - Linux, Windows and OS X.


## Installation

Install [RVM](https://rvm.io/):

```
$ gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
$ \curl -sSL https://get.rvm.io | bash -s stable
```

If you already have RVM installed, you may want to update it to the latest version:

```
$ rvm get stable
```

_Note:_ After the installation completes, you will need to `source ~/.rvm/scripts/rvm` before you can use RVM from your console.


Use RVM to install JRuby:

```
$ rvm install jruby
```

Switch RVM to use JRuby (optionally setting it to be default):
```
$ rvm use --default jruby
```

Install Pacer

```
$ gem install pacer
```


## Verify Installation

We can verify that Pacer was properly installed, using the IRB (Ruby's interactive shell):

```
$ irb
jruby-1.7.19 :001 > require 'pacer'
 => true
```

That's it, you're good to go.

<span class="label label-info">Tip:</span> Windows users may find it more convenient to use `jirb_swing`, instead of running IRB in the built-in CMD terminal.



