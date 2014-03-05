require 'set'
module Pacer
  module Core

    # The basic internal logic for routes and core route shared methods are
    # defined here. Many of these methods are designed to be specialized by
    # other modules included after Core::Route is included.
    module Route
      class << self
        protected
        def included(target)
          target.send :include, Enumerable
        end
      end

      # Replace the generated class name of this route with a specific
      # one by setting route_name.
      attr_accessor :route_name
      attr_accessor :info

      # Specify which pipe class will be instantiated when an iterator is created.
      attr_accessor :pipe_class

      # If true, elements won't be printed to STDOUT when #inspect is
      # called on this route.
      # @return [true, false]
      attr_accessor :hide_elements

      # If this piece of the route is useless in a lookahead, set this to true
      # and when it is at the tail of a lookahead, it will be removed
      # automatically. (for instance the property decoder, or wrap/unwrap)
      attr_accessor :remove_from_lookahead

      # If a route's function won't do the expected thing in a lookahead, set a
      # proc here that will correct the route. For instance:
      #
      #   g.v.lookahead { |v| v[:prop] }
      #
      # gets transformed to:
      #
      #   g.v.lookahead { |v| v.property?(:prop) }
      #
      attr_accessor :lookahead_replacement

      # Return which graph this route operates on.
      #
      # @return [PacerGraph]
      def graph
        config.fetch :graph do
          src = @back || @source
          src.graph if src.respond_to? :graph
        end
      end

      # Returns true if the given graph is the one this route operates on.
      def from_graph?(g)
        graph.equals g
      end

      def chain_route(args_hash)
        Pacer::RouteBuilder.current.chain self, args_hash
      end

      # The arguments passed to the pipe constructor.
      #
      # @overload pipe_args
      # @overload pipe_args=(args)
      #   @param [Object] args
      # @overload pipe_args=(args)
      #   @param [[Object]] args
      #
      # @return [[Object]] array of arguments
      attr_reader :pipe_args

      def pipe_args=(args)
        if args.is_a? Array
          @pipe_args = args
        else
          @pipe_args = [args]
        end
      end

      # Return true if this route is at the beginning of the route definition.
      def root?
        !@source.nil? or @back.nil?
      end

      # Prevents the route from being evaluated when it is inspected. Useful
      # for computationally expensive or one-time routes.
      #
      # @todo rename this method
      #
      # @return [self]
      def route
        @hide_elements = true
        self
      end

      # Returns the hash of variables used during the previous evaluation of
      # the route.
      #
      # The contents of vars is expected to be in a state relevant to the
      # latest route being evaluated and is primarily meant for internal use,
      # but YMMV.
      #
      # @todo It would maybe be better if the vars were tied to the
      #   thread context or preferably to the actual pipe instance in
      #   use. The current implementation of vars is not threadsafe if
      #   the same route is being used in multiple threads concurrently.
      #
      # @return [Hash]
      def vars
        if @back
          @back.vars
        else
          @vars ||= {}
        end
      end

      # Iterates over each element or object resulting from traversing the
      # route up to this point.
      #
      # @yield [item] if a block is given
      # @return [Enumerator] if no block is given
      def each
        iter = iterator
        iter = configure_iterator(iter)
        if block_given?
          while true
            yield iter.next
          end
        else
          iter
        end
      rescue Pacer::EmptyPipe, java.util.NoSuchElementException
        self
      end

      # Returns a single use pipe iterator based on this route.
      #
      # @yield [java.util.Iterator] the pipe. Very useful because this method will catch the pipe's java.util.NoSuchElementException when iteration is finished.
      # @return [java.util.Iterator] the pipe.
      def pipe
        iterator = each
        if block_given?
          yield iterator if block_given?
        else
          iterator
        end
      rescue Pacer::EmptyPipe, java.util.NoSuchElementException
        nil
      end

      def help(section = nil)
        general_topics = <<HELP
Some general help sections:
:routes     What are Pacer's routes?
:basics     Simple usage examples
:creation   How to create records
:tools      Some things you can do
:graphs     Available graphs
:help       How to contribute to Pacer's inline help
HELP
        if section == :help
          puts <<HELP
Contributions of help topics will be greatly apreciated.

Help topics should be added to the modules that they describe. General topics
help can be added here for now but will likely be moved eventually.

See lib/pacer/transform/map.rb for an example of how to define contextual help
topics.

If you add a general topic, remember to add it to the list above.

Remember to call super for unrecognized sections! :)

HELP
        elsif section == :routes
          puts <<HELP
Pacer's routes are a very efficient and fast way to deal with data.

The fundamental thing about them is that they are lazily evaluated, which
allows very expensive traversals to be defined, yet nearly always produces
results immediately with very low memory requirements, too.



HELP
        elsif section == :basics
          puts <<HELP
Pacer basics:

g = Pacer.tg                           # create an in-memory graph
                                       # - help(:graphs) for other types
g.v                                    # create a route to all vertices in the graph
                                       # vertices are your basic documents.
g.e                                    # ... or all edges
                                       # edges connect documents. They can have properties, too!
g.v(name: 'Sue', gender: 'male')       # find all boys named Sue
                                       # all elements are schemaless, so you
                                       # can specify any properties
g.v(name: 'Sue', gender: 'male').count # how many are there?
                                       # see how we can chain calls? Powerful
                                       # traversals can be defined this way.
g.v.out_e(:friend)                     # see Sue's 'friend' relationships
g.v.out_e(:friend).in_v                # continue on to his friends
g.v.out_e(:friend).in_v.out(:friends)  # continue on to his friends-of-friends
g.v.in(:friend)                        # see who has friended Sue.
                                       # all edges are directional to follow an
                                       # edge, use #out or #out_e; to go
                                       # backwards along an edge, use #in or
                                       # #in_e

#{general_topics}

HELP
        elsif section == :creation
          puts <<HELP
How we can create records in a Pacer graph:

g = Pacer.tg                          # create a new in-memory graph to play with
sue = g.create_vertex name: 'Sue', gender: 'male'
                                      # create a record with properties
ghost = g.create_vertex               # get lazy and create an empty one
sue.add_edges_to :friend, ghost       # Sue has friended the ghost.
                                      # This relationship can be traversed in
                                      # both directions so a reverse
                                      # relationship is *not* required, but can
                                      # be created:
ghost.add_edges_to :friend, sue, type: 'spooky'
                                      # We can also create edges with properties
sue[:age] = 27                        # It's that easy to add or change a property
sue['fav foods'] = [pie, donuts]      # Pacer can shoehorn any data into the
                                      # graph as long as it's serializable.

#{general_topics}

HELP
        elsif section == :tools
          puts <<HELP

HELP
        elsif section == :graphs or section == :plugins
          puts <<HELP
Various graphs are supported in their own Rubygems. Check out pacer-neo4j,
pacer-orient, pacer-dex for now. New graphs emerge frequently and I hope to
support many of them.

Search rubygems.org or github for projects that start with "pacer-" to see what
other plugins exist as well.

#{general_topics}

HELP
        else
          if section
            puts "Unrecognized help section specified"
            puts
          elsif not is_a? Graph
            puts "No specialized help has been defined for this step yet."
            puts
          end
          puts <<HELP
How to use Pacer's inline help:

You can use Pacer.help(:section) to print help on general topics, or get
context-specific help by calling help on any route. For example:

    graph.v.out_e.map.help  # will give you help about the map command.

#{general_topics}

General options (may not be available for all methods)

  element_type: Symbol  Set what type of element is emitted from this step.
      registered types: #{ Pacer::RouteBuilder.current.element_types.keys.map(&:inspect).join ', ' }

  graph: PacerGraph     If the route contains graph elements, specify that they
                        are from this graph

  route_name: String    Name for this route when inspecting it in IRB.

  info: String          Put what you want here. Appears when the route is inspected.

  extensions: [Module]  Extra extensions to add to the route.

  wrapper: Class         Wrap elements in this class.
      For each element, wrapper.new(graph, element) happens

HELP
        end
        description
      end

      def description(join = ' -> ')
        "#<#{inspect_strings.join(join)}>"
      end

      # Returns a string representation of the route definition. If there are
      # less than Graph#inspect_limit matches, it will also output all matching
      # elements formatted in columns up to a maximum character width of
      # Graph#columns.  If this output behaviour is undesired, it may be turned
      # off by calling #route on the current route.
      #
      # @return [String]
      def inspect(limit = nil)
        if Pacer.hide_route_elements or hide_elements or source_iterator.nil?
          description
        else
          read_transaction do
            Pacer.hide_route_elements do
              count = 0
              limit ||= Pacer.inspect_limit
              results = collect do |v|
                count += 1
                if count > limit
                  puts "Total: > #{ limit } (Pacer.inspect_limit)"
                  return route.inspect
                end
                v.inspect
              end
              if count > 0
                lens = results.collect { |r| r.length }
                max = lens.max
                cols = (Pacer.columns / (max + 1).to_f).floor
                cols = 1 if cols < 1
                if cols == 1
                  template_part = ['%s']
                else
                  template_part = ["%-#{max}s"]
                end
                template = (template_part * cols).join(' ')
                results.each_slice(cols) do |row|
                  template = (template_part * row.count).join(' ') if row.count < cols
                  puts template % row
                end
              end
              puts "Total: #{ count }"
              description
            end
          end
        end
      end

      # Returns true if the other route is defined the same as the current route.
      #
      # Note that block filters will prevent matches even with identically
      # defined routes unless the routes are actually the same object.
      # @return [true, false]
      def ==(other)
        other.class == self.class and
          other.function == function and
          other.element_type == element_type and
          other.back == back and
          other.source == source
      end

      # Returns true if this route currently has no elements.
      def empty?
        none?
      end

      def set_wrapper(wrapper)
        chain_route wrapper: wrapper
      end

      # If any objects in the given array are modules that contain a Route
      # submodule, extend this route with the Route module.
      # @return [self]
      def add_extensions(exts)
        chain_route extensions: (extensions - exts) + exts
      end

      def set_extensions(exts)
        chain_route extensions: exts, wrapper: nil
      end

      def no_extensions
        chain_route(:extensions => [], :wrapper => nil)
      end

      # Change the source of this route.
      #
      # @note all routes derived from any route in the chain will be
      #   affected so use with caution.
      #
      # @param [Enumerable, Enumerator] src the data source.
      def set_pipe_source(src)
        if @back
          @back.set_pipe_source src
        else
          self.source = src
        end
      end

      protected

      # Set the previous route in the chain.
      def back=(back)
        if back.is_a? Route and not back.is_a? PacerGraph
          @back = back
        else
          @back = nil
          @source = back
        end
      end

      # Return the route which is attached to the given route.
      def route_after(route)
        if route == self
          nil
        elsif @back
          if @back == route
            self
          elsif @back.is_a? Route
            @back.route_after(route)
          end
        end
      end

      # Overridden to extend the iterator to apply mixins
      # or wrap elements
      def configure_iterator(iter)
        iter
      end

      def get_section_route(name)
        if respond_to? :section_name and section_name == name
          self
        elsif @back
          @back.get_section_route(name)
        else
          raise ArgumentError, "Section #{ name } not found"
        end
      end

      # Returns a HashSet of element ids from the collection, but
      # only if all elements in the collection have an element_id.

      # This should not normally need to be set. It can be used to inject a route
      # into another route during iterator generation.
      def source=(source)
        @back = nil
        @source = source
      end

      # Get the actual source of data for this route.
      #
      # @return [java.util.Iterator]
      def source_iterator
        if @source
          iter = iterator_from_source(@source)
          iter.enablePath(true) if iter.respond_to? :enablePath
          iter
        elsif @back
          @back.send(:source_iterator)
        end
      end

      # Get the first and last pipes in the pipeline before the current
      # route's pipes are added.
      # @see #build_pipeline
      # @return [[com.tinkerpop.pipes.Pipe, com.tinkerpop.pipes.Pipe], nil]
      def pipe_source
        if @source
          nil
        elsif @back
          @back.send(:build_pipeline)
        end
      end

      # Return an iterator for a variety of source object types.
      def iterator_from_source(src)
        if src.is_a? PacerGraph
          al = java.util.ArrayList.new
          al << src.blueprints_graph
          al.iterator
        elsif src.is_a? Pacer::Wrappers::ElementWrapper
          Pacer::Pipes::EnumerablePipe.new src.element
        elsif src.is_a? Proc
          iterator_from_source(src.call)
        elsif src.is_a? Iterator
          src
        elsif src
          Pacer::Pipes::EnumerablePipe.new src
        end
      end

      # Return an iterator for this route loading data from all previous routes
      # in the chain.
      def iterator
        Pacer.executing_route self
        start, end_pipe = build_pipeline
        if start
          src = source_iterator
          Pacer.debug_source = src if Pacer.debug_pipes
          start.setStarts src
          end_pipe
        elsif end_pipe
          raise "End pipe without start pipe"
        else
          pipe = Pacer::Pipes::IdentityPipe.new
          pipe.setStarts source_iterator
          pipe
        end
      end

      # This is the default implementation of the method used to create
      # the specialized pipe for each route instance. It is overridden
      # in most function modules to produce the pipe needed to perform
      # that function.
      #
      # @see Filter modules in this namespace override this method
      # @see Transform modules in this namespace override this method
      # @see SideEffect modules in this namespace override this method
      #
      # @param [com.tinkerpop.pipes.Pipe] the pipe emitting the source
      #   data for this pipe
      # @return [com.tinkerpop.pipes.Pipe] the pipe that emits the
      #   resulting data from this step
      def attach_pipe(end_pipe)
        if pipe_class
          if pipe_args
            begin
              pipe = pipe_class.new(*pipe_args)
            rescue ArgumentError
              raise ArgumentError, "Invalid args for pipe: #{ pipe_class.inspect }.new(*#{pipe_args.inspect})"
            end
          else
            begin
              pipe = pipe_class.new
            rescue ArgumentError
              raise ArgumentError, "Invalid args for pipe: #{ pipe_class.inspect }.new()"
            end
          end
          pipe.setStarts end_pipe if end_pipe
          pipe
        else
          end_pipe
        end
      rescue NativeException => e
        if e.cause.name == 'java.lang.InstantiationException'
          raise Exception, "Unable to instantiate abstract class #{ pipe_class }"
        else
          raise
        end
      end

      # Walks back along the chain of routes to build the series of Pipe
      # objects that represent this route.
      #
      # @return [[com.tinkerpop.pipes.Pipe, com.tinkerpop.pipes.Pipe]]
      #   start and end pipe in the pipeline. The start pipe gets the
      #   source applied to it, the end pipe produces the result when its
      #   next method is called.
      def build_pipeline
        start, end_pipe = pipe_source
        pipe = attach_pipe(end_pipe)
        Pacer.debug_pipes << { :name => inspect_class_name, :start => start, :end => pipe } if Pacer.debug_pipes
        [start || pipe, pipe]
      end

      # Returns an array of strings representing each route object in the
      # chain.
      # @return [[String]]
      def inspect_strings
        ins = []
        ins += @back.inspect_strings unless root?

        ins << inspect_string
        ins
      end

      # Returns the string representing just this route instance.
      # @return [String]
      def inspect_string
        return route_name if route_name
        if pipe_class
          ps = pipe_class.name
          if ps =~ /FilterPipe$/
            ps = ps.split('::').last.sub(/FilterPipe/, '')
            if pipe_args
              pipeargs = pipe_args.collect do |arg|
                if arg.is_a? Enumerable and arg.count > 10
                  "[...#{ arg.count } items...]"
                else
                  arg.to_s
                end
              end
              ps = "#{ps}(#{pipeargs.join(', ')})" if pipeargs.any?
            end
          elsif pipe_args
            ps = pipe_args.join(', ')
          end
        end
        s = inspect_class_name
        s = "#{s}(#{ ps })" if ps and ps != ''
        s
      end

      # Return the class name of the current route.
      # @return [String]
      def inspect_class_name
        s = "#{self.class.name.split('::').last.sub(/Route$/, '')}"
        s = "#{s} #{ info }" if info
        s
      end

      def read_transaction(&block)
        if graph
          graph.read_transaction &block
        else
          yield
        end
      end

    end
  end
end
