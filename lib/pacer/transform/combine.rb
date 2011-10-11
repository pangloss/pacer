module Pacer
  module Routes
    module RouteOperations
      def combine(existing_multi_graph = nil, &block)
        chain_route :transform => :combine,
          element_type: :vertex,
          existing_multi_graph: existing_multi_graph,
          graph: (existing_multi_graph || Pacer::MultiGraph.new),
          block: block
      end
    end
  end

  module Transform
    module Combine
      class CombinePipe < Pacer::Pipes::RubyPipe
        import com.tinkerpop.pipes.sideeffect.SideEffectPipe
        import java.util.ArrayList
        import java.util.LinkedList

        include SideEffectPipe rescue nil # may raise exception on reload.

        attr_accessor :multi_graph, :current_keys, :current_values, :join_on
        attr_reader :key_expando, :key_end, :values_pipes

        def initialize(multi_graph)
          super()
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
          pipe.next
        end

        def prepare_aggregate_pipe(from_pipe, to_pipe)
          expando = Pacer::Pipes::ExpandablePipe.new
          expando.setStarts ArrayList.new.iterator
          from_pipe.setStarts(expando)
          agg_pipe = com.tinkerpop.pipes.sideeffect.AggregatePipe.new LinkedList.new
          cap_pipe = com.tinkerpop.pipes.transform.SideEffectCapPipe.new agg_pipe
          agg_pipe.setStarts to_pipe
          cap_pipe.setStarts to_pipe
          [expando, cap_pipe]
        end
      end

      include Pacer::Core::SideEffect

      attr_accessor :existing_multi_graph, :key_route, :values_routes
      attr_writer :join_on

      def block=(block)
        if block
          @key_route = block_route(block)
        else
          @key_route = nil
        end
        self
      end

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
        pipe = CombinePipe.new(existing_multi_graph)
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
    
