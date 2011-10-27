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

      # Set which graph this route will operate on.
      #
      # @todo move this to graph routes.
      attr_writer :graph

      # Return which graph this route operates on.
      #
      # @todo move this to graph routes.
      #
      # @return [GraphMixin]
      def graph
        @graph = nil unless defined? @graph
        @graph ||= (@back || @source).graph rescue nil
      end

      # Returns true if the given graph is the one this route operates on.
      def from_graph?(g)
        graph.equals g
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

      # Iterates over each element resulting from traversing the route up to this point.
      #
      # @todo move with graph-specific code or make more general.
      #
      # @yield [item] if a block is given
      # @return [Enumerator] if no block is given
      def each_element
        iter = iterator
        if wrapper
          iter.extend IteratorWrapperMixin
          iter.wrapper = wrapper
          iter.extensions = @extensions if @extensions.any?
        elsif extensions and extensions.any?
          iter.extend IteratorExtensionsMixin
          iter.extensions = extensions 
        else
          iter.extend IteratorMixin
        end
        iter.graph = graph
        if block_given?
          while true
            yield iter.next
          end
        else
          iter
        end
      rescue java.util.NoSuchElementException
        self
      end

      # Iterates over each element resulting from traversing the route
      # up to this point. Extends each element with
      # {Extensions::BlockFilterElement} to make route context
      # available.
      #
      # @todo move with graph-specific code or make more general.
      #
      # @yield [ElementMixin(Extensions::BlockFilterElement)] if a block is given
      # @return [Enumerator(IteratorContextMixin)] if no block is given
      def each_context
        iter = iterator
        if block_given?
          g = graph
          while true
            item = iter.next
            item.graph ||= g
            item.extend Pacer::Extensions::BlockFilterElement
            item.back = self
            yield item
          end
        else
          iter.extend IteratorContextMixin
          iter.graph = graph
          iter.context = self
          iter
        end
      rescue java.util.NoSuchElementException
        self
      end

      # Iterates over each object resulting from traversing the route up
      # to this point.
      #
      # @yield [Object] if a block is given
      # @return [Enumerator] if no block is given
      def each_object
        iter = iterator
        if block_given?
          while true
            item = iter.next
            yield item
          end
        else
          iter
        end
      rescue java.util.NoSuchElementException
        self
      end

      def pipe(iterator_method = :each)
        iterator = send(iterator_method) 
        yield iterator if block_given?
        iterator
      rescue java.util.NoSuchElementException
        iterator
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
          "#<#{inspect_strings.join(' -> ')}>"
        else
          Pacer.hide_route_elements do
            count = 0
            limit ||= Pacer.inspect_limit
            results = collect do |v|
              count += 1
              return route.inspect if count > limit
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
            "#<#{inspect_strings.join(' -> ')}>"
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

      # Add an extension to the route.
      #
      # If the extension has a Route module inside it, this route will
      # be extended with the extension's Route module.
      #
      # If the extension has a Vertex or Edge module inside it, any vertices
      # or edges emitted from this route will be extended with with the
      # extension as well.
      #
      # @see VertexMixin#add_extensions
      # @see EdgeMixin#add_extensions
      #
      # @return [self]
      def add_extension(mod, add_to_list = true)
        return self unless mod.respond_to?(:const_defined?)
        is_extension = false
        if mod.const_defined? :Route
          is_extension = true
          extend mod::Route
        end
        if add_to_list and (is_extension or mod.const_defined? :Vertex or mod.const_defined? :Edge)
          @extensions << mod
        end
        self
      end

      def set_wrapper(wrapper)
        if wrapper.respond_to? :extensions
          wrapper.extensions.each do |ext|
            add_extension ext, false
          end
        end
        @wrapper = wrapper
        self
      end
      alias wrapper= set_wrapper

      def wrapper
        @wrapper
      end

      # Add extensions to this route.
      #
      # @see #add_extension
      def extensions=(exts)
        add_extensions Set[*exts]
      end

      # Get the set of extensions currently on this route.
      #
      # The order of extensions for custom defined wrappers are
      # guaranteed. If a wrapper is iterated with additional extensions,
      # a new wrapper will be created dynamically with the original
      # extensions in order followed by any additional extensions in
      # undefined order.
      #
      # If a wrapper is present, returns an Array. Otherwise a Set.
      #
      # @return [Enumerable[extension]]
      def extensions
        if wrapper
          wrapper.extensions + @extensions.to_a
        else
          @extensions
        end
      end

      # If any objects in the given array are modules that contain a Route
      # submodule, extend this route with the Route module.
      # @see #add_extension
      # @return [self]
      def add_extensions(exts)
        modules = exts.select { |obj| obj.is_a? Module or obj.is_a? Class }
        modules.each do |mod|
          add_extension(mod)
        end
        self
      end

      def no_extensions
        chain_route(:extensions => nil, :wrapper => nil)
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
        if back.is_a? Route and not back.is_a? GraphMixin
          @back = back
        else
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
          iterator_from_source(@source)
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
        if src.is_a? Pacer::GraphMixin
          al = java.util.ArrayList.new
          al << src
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
        start, end_pipe = build_pipeline
        if start
          src = source_iterator
          Pacer.debug_source = src if Pacer.debug_pipes
          start.set_starts src
          end_pipe
        elsif end_pipe
          raise "End pipe without start pipe"
        else
          pipe = Pacer::Pipes::IdentityPipe.new
          pipe.set_starts source_iterator
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
          pipe.set_starts end_pipe if end_pipe
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

    end
  end
end
