module Pacer
  module Routes
    module RouteOperations
      def join(name, options = {}, &block)
        args = { :transform => :join,
          element_type: :vertex,
          graph: options.fetch(:multi_graph, Pacer::MultiGraph.new),
          from_graph: graph
        }
        args[:multi_graph] = options[:multi_graph] if options[:multi_graph]
        route = chain_route(args).route.join(options.fetch(:key, :key)) { |v| v }
        route.join(name, &block)
      end

      def collect_with(multigraph)
        vars[:multigraph] = multigraph
      end

      def collect_as(name, opts = {})
        process do |element|
          g = vars[:multigraph] ||= Pacer::MultiGraph.new
          v = vars[name] = g.create_vertex
          v[name] = element
          within = opts[:within]
          if within
            within_v = vars[within]
            g.create_edge nil, v, within_v, :within
          end
        end
      end

      def add_to(collection_name, name = nil)
        process do |element|
          v = vars[collection_name]
          if name
            existing = v[name]
            if existing
              existing << element
            else
              v[name] = [element]
            end
          end
          if block_given?
            yield v, element
          end
        end
      end

      def map_to(collection_name, name)
        process do |element|
          v = vars[collection_name]
          existing = v[name]
          if block_given?
            mapped = yield element, v
          else
            mapped = element
          end
          if existing
            existing << mapped
          else
            v[name] = [mapped]
          end
        end
      end

      def reduce_to(collection_name, name, starting_value)
        process do |element|
          v = vars[collection_name]
          total = v[name]
          if total
            v[name] = yield total, element
          else
            v[name] = yield starting_value, element
          end
        end
      end

      def execute!
        p = pipe
        while p.hasNext
          p.next
        end
        self.route
      end

      def collected(name = nil)
        if name
          map(graph: vars[:multigraph], element_type: :vertex) { vars[name] }
        else
          execute!.vars[:multigraph]
        end
      end
    end
  end

  module Transform
    module Join
      class CombinePipe < Pacer::Pipes::RubyPipe
        import com.tinkerpop.pipes.sideeffect.SideEffectPipe
        import java.util.ArrayList
        import java.util.LinkedList

        include SideEffectPipe rescue nil # may raise exception on reload.

        attr_accessor :multi_graph, :current_keys, :current_values, :join_on
        attr_reader :key_expando, :key_end, :values_pipes, :from_graph

        def initialize(from_graph, multi_graph)
          super()
          @from_graph = from_graph
          @multi_graph = multi_graph || Pacer::MultiGraph.new
          @values_pipes = []
          @current_keys = []
          @current_values = []
        end

        def setKeyPipe(from_pipe, to_pipe)
          @key_expando, @key_end = prepare_aggregate_pipe(from_pipe, to_pipe)
        end

        def addValuesPipe(name, from_pipe, to_pipe)
          values_pipes << [name, *prepare_aggregate_pipe(from_pipe, to_pipe)]
        end

        def getSideEffect
          multi_graph
        end

        protected

        def processNextStart
          while true
            if current_keys.empty?
              element = starts.next
              element.graph = from_graph if element.respond_to? :graph
              self.current_keys = get_keys(element)
              self.current_values = get_values(element) unless current_keys.empty?
            else
              combined = multi_graph.create_vertex
              combined.join_on join_on if join_on
              combined[:key] = current_keys.removeFirst
              current_values.each do |key, values|
                combined[key] = values
              end
              return combined
            end
          end
        rescue NativeException => e
          if e.cause.getClass == Pacer::NoSuchElementException.getClass
            raise e.cause
          else
            raise e
          end
        end

        def get_keys(element)
          array = LinkedList.new
          if key_expando
            array.addAll next_results(key_expando, key_end, element)
          else
            array.add nil
          end
          array
        end

        def get_values(element)
          values_pipes.map do |name, expando, to_pipe|
            [name, next_results(expando, to_pipe, element)]
          end
        end

        # doesn't need to be spun out because it's a capped aggregator
        def next_results(expando, pipe, element)
          pipe.reset
          expando.add element, ArrayList.new, nil
          array = pipe.next
          array.each { |element| element.graph = from_graph if element.respond_to? :graph }
          array
        end

        def prepare_aggregate_pipe(from_pipe, to_pipe)
          expando = Pacer::Pipes::ExpandablePipe.new
          expando.setStarts ArrayList.new.iterator
          from_pipe.setStarts(expando)
          if from_pipe == to_pipe and to_pipe.is_a? Pacer::Pipes::IdentityPipe
            cap_pipe = to_pipe
          else
            agg_pipe = com.tinkerpop.pipes.sideeffect.AggregatePipe.new LinkedList.new
            cap_pipe = com.tinkerpop.pipes.transform.SideEffectCapPipe.new agg_pipe
            agg_pipe.setStarts to_pipe
            cap_pipe.setStarts to_pipe
          end
          [expando, cap_pipe]
        end
      end

      include Pacer::Core::SideEffect

      attr_accessor :existing_multi_graph, :key_route, :values_routes, :from_graph
      attr_writer :join_on

      def key(&block)
        @key_route = block_route(block)
        self
      end

      def join(name, &block)
        @values_routes << [name, block_route(block)]
        self
      end

      def join_on(*keys)
        @join_on = keys
        self
      end

      protected

      def after_initialize
        @values_routes = []
      end

      def attach_pipe(end_pipe)
        pipe = CombinePipe.new(from_graph, existing_multi_graph)
        self.graph = pipe.multi_graph
        pipe.setKeyPipe *key_route.send(:build_pipeline) if key_route
        pipe.join_on = @join_on
        values_routes.each do |name, route|
          pipe.addValuesPipe name, *route.send(:build_pipeline)
        end
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def block_route(block)
        empty = Pacer::Route.empty(self)
        route = block.call(empty)
        if route == empty
          identity_route.route
        else
          route.route
        end
      end

      def identity_route
        Pacer::Route.empty(self).chain_route(:pipe_class => Pacer::Pipes::IdentityPipe,
                                             :route_name => '@').route
      end

      def inspect_string
        "#{ inspect_class_name }(#{ key_route.inspect }: #{ Hash[values_routes].inspect })"
      end
    end
  end
end
    
