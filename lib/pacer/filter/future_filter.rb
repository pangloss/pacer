module Pacer
  module Routes
    module RouteOperations
      def lookahead(&block)
        chain_route :lookahead => block, :has_element => true
      end

      def neg_lookahead(&block)
        chain_route :lookahead => block, :has_element => false
      end
    end
  end

  module Filter
    module FutureFilter
      def self.triggers
        [:lookahead]
      end

      attr_accessor :lookahead, :has_element

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::FutureFilterPipe.new(lookahead_pipe, has_element)
        pipe.set_starts(end_pipe)
        pipe
      end

      def lookahead_route
        empty = Pacer::Route.new :filter => :empty, :back => self
        r = @lookahead.call(empty)
        r
      end

      def lookahead_pipe
        # The lookahead route actually requires a pipeline object because it
        # changes the starts on the same object as it requests the next result
        # from.
        s, e = lookahead_route.send(:build_pipeline)
        if s.equal?(e)
          s
        else
          Pacer::Pipes::Pipeline.new s, e
        end
      end

      def inspect_string
        "#{ inspect_class_name }(#{ lookahead_route.inspect })"
      end
    end
  end
end
