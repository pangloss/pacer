module Pacer
  module Routes
    module RouteOperations
      def group
        chain_route :transform => :group
      end
    end
  end

  # Here's an example of the syntax I want:
  # trims.limit(10).group.key { |t| t[:id] }.values { |t| t.out_e.counted.cap }

  module Transform
    module Group
      attr_accessor :key_route, :values_route

      def key(&block)
        @key_route = map_route block
        self
      end

      def values(&block)
        @values_route = map_route block
        self
      end

      def key_route(&block)
        @key_route = block_route(block)
        self
      end

      def values_route(&block)
        @values_route = block_route(block)
        self
      end

      protected

      def map_route(block)
        Pacer::Route.empty(self).
          chain_route({:transform => :map, :block => block, :element_type => :object}).
          route
      end

      def block_route(block)
        block.call(Pacer::Route.empty(self)).route
      end

      def identity_route
        Pacer::Route.empty(self).chain_route(:pipe_class => com.tinkerpop.pipes.IdentityPipe,
                                             :route_name => '@').route
      end

      def ensure_routes
        @key_route ||= identity_route
        @values_route ||= identity_route
        @key_route.route
        @values_route.route
      end

      def attach_pipe(end_pipe)
        ensure_routes
        pipe = Pacer::Pipes::GroupPipe.new
        pipe.setKeyPipe *@key_route.send(:build_pipeline)
        pipe.setValuesPipe *@values_route.send(:build_pipeline)
        pipe.setStarts end_pipe
        pipe
      end

      def inspect_string
        ensure_routes
        "#{ inspect_class_name }([#{ @key_route.inspect }, #{ @values_route.inspect }])"
      end
    end
  end
end
