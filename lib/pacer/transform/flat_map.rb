module Pacer
  module Routes
    module RouteOperations
      def flat_map(opts = {}, &block)
        map(&block).scatter(opts)
      end
    end
  end
end
