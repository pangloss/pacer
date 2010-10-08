module Pacer
  module Routes
    module Base
      module RouteClassMethods
        def vertex_path(name)
        end

        def edge_path(name)
        end

        def path(name)
        end

        # An alternate constructor for creating a route that uses the given
        # pipe class initialized with the given arguments.
        def pipe_filter(back, pipe_class, *args, &block)
          f = new(back, nil, block, *args)
          f.pipe_class = pipe_class
          f
        end
      end

      def self.included(target)
        target.send :include, Enumerable
        target.extend RouteClassMethods
      end

      # The previous route in the path
      def back
        @back
      end

      # Returns the info.
      def info
        @info
      end

      # Store arbitrary info here. Usually a description of the route.
      def info=(str)
        @info = str
      end

      # TODO: is this method necessary?
      # Set which graph this route will operate on.
      def graph=(graph)
        @graph = graph
      end

      # Return which graph this route operates on.
      def graph
        @graph ||= (@back || @source).graph
      end

      # Returns true if the given graph is the one this route operates on.
      def from_graph?(g)
        graph == g
      end

      # TODO protect or remove method
      # Specify which pipe class will be instantiated when an iterator is created.
      def pipe_class=(klass)
        @pipe_class = klass
      end

      # Return true if this route is at the beginning of the route definition.
      def root?
        !@source.nil? or @back.nil?
      end

      # Prevents the route from being evaluated when it is inspected. Useful
      # for computationally expensive routes.
      def route
        @inspect_route = true
        self
      end

      # Returns the hash of variables used during the previous evaluation of
      # the route.
      #
      # The contents of vars is expected to be in a state relevant to the
      # latest route being evaluated and is primarily meant for internal use,
      # but YMMV.
      def vars
        if @back
          @back.vars
        else
          @vars
        end
      end

      # Argument may be either a path, a graph element or a symbol representing
      # a key to the vars hash. Prevents any matching elements from being
      # included in the results.
      def except(path)
        if path.is_a? Symbol
          route_class.pipe_filter(self, nil) { |v| v != v.vars[path] }
        else
          path = [path] unless path.is_a? Enumerable
          route_class.pipe_filter(self, Pacer::Pipes::CollectionFilterPipe, path.to_a, Pacer::Pipes::ComparisonFilterPipe::Filter::EQUAL)
        end
      end

      # Argument may be either a path, a graph element or a symbol representing
      # a key to the vars hash. Ensures that only matching elements will be
      # included in the results.
      def only(path)
        if path.is_a? Symbol
          route_class.pipe_filter(self, nil) { |v| v == v.vars[path] }
        else
          path = [path] unless path.is_a? Enumerable
          route_class.pipe_filter(self, Pacer::Pipes::CollectionFilterPipe, path.to_a, Pacer::Pipes::ComparisonFilterPipe::Filter::NOT_EQUAL)
        end
      end

      # Yields each matching element or returns an iterator if no block is given.
      def each
        iter = iterator(false)
        g = graph
        if block_given?
          while item = iter.next
            item.graph = g
            yield item
          end
        else
          iter.extend IteratorGraphMixin
          iter.graph = g
          iter
        end
      rescue NoSuchElementException
        self
      end

      # Yields each matching path or returns an iterator if no block is given.
      def each_path
        iter = iterator(true)
        g = graph
        if block_given?
          while item = iter.next
            path = iter.path
            path.each { |item| item.graph = g }
            yield path
          end
        else
          iter.extend IteratorMixin
          iter
        end
      rescue NoSuchElementException
        self
      end

      # Returns a string representation of the route definition. If there are
      # less than Graph#inspect_limit matches, it will also output all matching
      # elements formatted in columns up to a maximum character width of
      # Graph#columns.  If this output behaviour is undesired, it may be turned
      # off by calling #route on the current route.
      def inspect(limit = nil)
        if inspect_route
          "#<#{inspect_strings.join(' -> ')}>"
        else
          count = 0
          limit ||= graph.inspect_limit
          results = map do |v|
            count += 1
            return route.inspect if count > limit
            v.inspect
          end
          if count > 0
            lens = results.map { |r| r.length }
            max = lens.max
            cols = (graph.columns / (max + 1).to_f).floor
            cols = 1 if cols < 1
            template_part = ["%-#{max}s"]
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

      # Returns true if the other route is defined the same as the current route.
      #
      # Note that block filters will prevent matches even with identically
      # defined routes unless the routes are actually the same object.
      def ==(other)
        other.class == self.class and
          other.back == @back and
          other.instance_variable_get('@source') == @source
      end

      protected

      # Initializes some basic instance variables.
      def initialize_path(back = nil, filters = nil, block = nil, *pipe_args)
        if back.is_a? Base
          @back = back
        else
          @source = back
        end
        @filters = filters || []
        @block = block
        @pipe_args = pipe_args
      end

      # Return an array of filter options for the current route.
      def filters
        @filters ||= []
      end

      # Return the block filter for the current route.
      def block
        @block
      end

      # Set the previous route in the chain.
      def back=(back)
        @back = back
      end

      # Get the source of data for this route.
      def source(is_path_iterator)
        if @source
          if is_path_iterator
            Pacer::Pipes::PathIteratorWrapper.new(iterator_from_source(@source))
          else
            iterator_from_source(@source)
          end
        else
          @back.send(:iterator, is_path_iterator)
        end
      end

      # Return an iterator for a variety of source object types.
      def iterator_from_source(src)
        if src.is_a? Proc
          iterator_from_source(src.call)
        elsif src.is_a? Iterator
          src
        elsif src
          Pacer::Pipes::EnumerablePipe.new src
        end
      end

      # Return an iterator for this route loading data from all previous routes
      # in the chain. If is_path_iterator is true, then return an iterator that
      # yields arrays of the path through the graph successfully followed by
      # the route.
      def iterator(is_path_iterator)
        @vars = {}
        pipe = nil
        prev_path_iterator = nil
        if @pipe_class
          prev_path_iterator = prev_pipe = source(is_path_iterator)
          pipe = @pipe_class.new(*@pipe_args)
          pipe.set_starts prev_pipe
        else
          prev_path_iterator = pipe = source(is_path_iterator)
        end
        pipe = filter_pipe(pipe, filters, @block)
        pipe = yield pipe if block_given?
        if is_path_iterator
          pipe = Pacer::Pipes::PathIteratorWrapper.new(pipe, prev_path_iterator)
        end
        pipe
      end

      # Boolean whether the route alone should be returned by inspect. If
      # false, the route data will also be displayed.
      def inspect_route
        @inspect_route
      end

      # Returns an array of strings representing each route object in the
      # chain.
      def inspect_strings
        ins = []
        ins += @back.inspect_strings unless root?

        if @pipe_class
          ps = @pipe_class.name
          pipeargs = @pipe_args.map { |a| a.to_s }.join(', ')
          if ps =~ /FilterPipe$/
            ps = ps.split('::').last.sub(/FilterPipe/, '')
            if @pipe_args.any?
              pipeargs = @pipe_args.map { |a| a.to_s }.join(', ')
              ps = "#{ps}(#{pipeargs})"
            end
          else
            ps = @pipe_args
          end
        end
        fs = "#{filters.inspect}" if filters.any?
        bs = '&block' if @block

        s = inspect_class_name
        if ps or fs or bs
          s = "#{s}(#{ [ps, fs, bs].compact.join(', ') })"
        end
        ins << s
        ins
      end

      # Return the class name of the current route.
      def inspect_class_name
        s = "#{self.class.name.split('::').last.sub(/Route$/, '')}"
        s = "#{s} #{ @info }" if @info
        s
      end

      # Appends the defined filter pipes to narrow the results passed through
      # the pipes for this route object.
      def filter_pipe(pipe, args_array, block)
        if args_array and args_array.any?
          pipe = args_array.select { |arg| arg.is_a? Hash }.inject(pipe) do |p, hash|
            hash.inject(p) do |p2, (key, value)|
              new_pipe = Pacer::Pipes::PropertyFilterPipe.new(key.to_s, value.to_java, Pacer::Pipes::ComparisonFilterPipe::Filter::NOT_EQUAL)
              new_pipe.set_starts p2
              new_pipe
            end
          end
        end
        if block
          pipe = Pacer::Pipes::BlockFilterPipe.new(pipe, self, block)
        end
        pipe
      end
    end
  end
end
