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
        @future_filter = [block, true]
      end

      def neg_block=(block)
        @future_filter = [block, false]
      end

      protected

      def after_initialize
        @future_filter = nil unless defined? @future_filter
        @route = nil unless defined? @route
      end

      def attach_pipe(end_pipe)
        pipe = FutureFilterPipe.new(lookahead_pipe)
        pipe.set_starts(end_pipe) if end_pipe
        pipe
      end

      def lookahead_route
        if @future_filter
          block, has_elements = @future_filter
          @future_filter = nil
          route = block.call(Pacer::Route.empty(self))
          if min or max
            route = route.has_count_route(:min => min, :max => max).is(true)
          end
          unless has_elements
            route = route.chain_route(:element_type => :object, :pipe_class => Pacer::Pipes::IsEmptyPipe, :route_name => 'negate')
          end
          @route = route
        elsif @route
          @route
        end
      end

      def lookahead_pipe
        Pacer::Route.pipeline(lookahead_route)
      end

      def inspect_string
        "#{ inspect_class_name }(#{ lookahead_route.inspect })"
      end
    end
  end
end
