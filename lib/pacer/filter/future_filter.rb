module Pacer
  module Routes
    module RouteOperations
      def lookahead(&block)
        chain_route :filter => :future, :block => block
      end

      def neg_lookahead(&block)
        chain_route :filter => :future, :neg_block => block
      end
    end
  end

  module Filter
    module FutureFilter
      def block=(block)
        @routes = [lookahead_route(block)]
        @has_elements = [true]
      end

      def neg_block=(block)
        @routes = [lookahead_route(block)]
        @has_elements = [false]
      end

      def or(has_element = true, &block)
        if block
          lookahead_routes << lookahead_route(block)
          has_elements << has_element
          self
        else
          Proxy.new(self, extensions)
        end
      end

      def lookahead_routes
        @routes ||= []
      end

      def has_elements
        @has_elements ||= []
      end

      protected

      def attach_pipe(end_pipe)
        if lookahead_routes.count > 1
          pipe = Pacer::Pipes::FutureOrFilterPipe.new(*lookahead_pipes)
          pipe.setShouldHaveResults *has_elements
        else
          pipe = Pacer::Pipes::FutureFilterPipe.new(lookahead_pipes.first, has_elements.first)
        end
        pipe.set_starts(end_pipe) if end_pipe
        pipe
      end

      def lookahead_route(block)
        empty = Pacer::Route.new :filter => :empty, :back => self
        r = block.call(empty)
        r
      end

      def lookahead_pipes
        lookahead_routes.map do |route|
          Pacer::Route.pipeline(route)
        end
      end

      def inspect_string
        "#{ inspect_class_name }(#{ lookahead_routes.zip(has_elements).map { |r, he| (he ? '' : 'NOT ') + r.inspect }.join(' | ') })"
      end


      class Proxy
        def initialize(route, extensions)
          @route = route
          extensions.each do |e|
            if e.const_defined? 'Route'
              extend e.const_get 'Route'
            end
          end
        end

        def lookahead(&block)
          @route.or(true, &block)
        end

        def neg_lookahead(&block)
          @route.or(false, &block)
        end
      end
    end
  end
end
