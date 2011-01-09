module Pacer
  module Routes
    module RouteOperations
      def lookahead(&block)
        chain_route(:back => self, :lookahead => block)
      end

      def neg_lookahead(&block)
        chain_route(:back => self, :lookahead => block)
      end
    end
  end

  module Filter
    module FutureFilter
      def self.triggers
        [:lookahead]
      end

      def lookahead=(block)
        @lookahead = block
      end

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::FutureFilterPipe.new(lookahead_pipe)
        pipe.set_starts(end_pipe)
        pipe
      end

      def lookahead_route
        empty = FilterRoute.new :filter => :empty, :back => self
        @lookahead.call(empty)
      end

      def lookahead_pipe
        lookahead_route.send :build_pipeline
      end

      def inspect_string
        "#{ inspect_class_name }(#{ lookahead_route.inspect })"
      end
    end
  end
end
