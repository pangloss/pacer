module Pacer
  module Routes
    module RouteOperations
      def lookahead(opts = {}, &block)
        chain_route({ :filter => :future, :block => block }.merge(opts))
      end

      def neg_lookahead(opts = {}, &block)
        chain_route({ :filter => :future, :neg_block => block }.merge(opts))
      end
    end
  end

  module Filter
    module FutureFilter
      import com.tinkerpop.pipes.filter.FutureFilterPipe

      attr_accessor :min, :max

      def block=(block)
        @blocks = [block]
        @has_elements = [true]
      end

      def neg_block=(block)
        @blocks = [block]
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

      def after_initialize
        if @blocks
          @routes = @blocks.map { |block| lookahead_route(block) }
          @blocks = nil
        end
      end

      def attach_pipe(end_pipe)
        if lookahead_routes.count > 1
          # TODO use or filter
          pipe = Pacer::Pipes::FutureOrFilterPipe.new(*lookahead_pipes)
          pipe.setShouldHaveResults *has_elements
        else
          if has_elements.first
            lookahead = lookahead_pipes.first
          else
            lookahead = Pacer::Pipes::IsEmptyPipe.new
            lookahead.setStarts lookahead_pipes.first
          end
          pipe = FutureFilterPipe.new(lookahead)
        end
        pipe.set_starts(end_pipe) if end_pipe
        pipe
      end

      def lookahead_route(block)
        route = block.call(Pacer::Route.empty(self))
        if min or max
          route.has_count_route(:min => min, :max => max).is(true)
        else
          route
        end
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
