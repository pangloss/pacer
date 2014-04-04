module Pacer
  module Routes
    module RouteOperations
      def identity
        chain_route route_name: 'identity', pipe_class: com.tinkerpop.pipes.IdentityPipe
      end
    end
  end
end

