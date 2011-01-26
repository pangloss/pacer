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
      attr_accessor :key_route, :values_routes

      def key(&block)
        @key_route = map_route block
        self
      end

      def values(&block)
        @values_routes << map_route(block)
        self
      end

      def key_route(&block)
        @key_route = block_route(block)
        self
      end

      def values_route(&block)
        @values_routes << block_route(block)
        self
      end

      def combine
        hash = {}
        each do |key, value_sets|
          a = hash[key]
          unless a
            a = []
            hash[key] = a
            value_sets.each { a << [] }
          end
          value_sets.each_with_index do |values, idx|
            values.each do |value|
              a[idx] << value
            end
          end
        end
        hash
      end

      def reduce(start)
        if start.is_a? Proc
          hash = Hash.new(&start)
        else
          hash = Hash.new(start)
        end
        each do |key, value_sets|
          value_sets.each_with_index do |values, idx|
            values.each do |value|
              hash[key] = yield hash[key], key, value
            end
          end
        end
        hash
      end

      protected

      def after_initialize
        @values_routes = []
      end

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
        key_route = @key_route
        values_routes = @values_routes
        key_route ||= identity_route
        values_routes = [identity_route] if values_routes.empty?
        key_route.route
        values_routes.each { |r| r.route }
        [key_route, values_routes]
      end

      def attach_pipe(end_pipe)
        key_route, values_routes = ensure_routes
        pipe = Pacer::Pipes::GroupPipe.new
        pipe.addKeyPipe *key_route.send(:build_pipeline)
        values_routes.each do |route|
          pipe.addValuesPipe *route.send(:build_pipeline)
        end
        pipe.setStarts end_pipe
        pipe
      end

      def inspect_string
        key_route, values_routes = ensure_routes
        "#{ inspect_class_name }(#{ key_route.inspect }, #{ values_routes.inspect })"
      end
    end
  end
end
