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

      def iterator
        # generate pipe to pass to the FutureFilterPipe
        raise 'todo'
      end

      def pipe
        Pacer::Pipes::FutureFilterPipe
      end

      def lookahead=(block)
        @lookahead = block
      end
    end
  end
end
