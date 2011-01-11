module Pacer
  module Routes
    module RouteOperations
      # Do not return duplicate elements.
      def uniq(*filters, &block)
        Pacer::Route.property_filter_before(self, filters, block) do |r|
          chain_route :pipe_class => Pacer::Pipes::DuplicateFilterPipe, :route_name => 'uniq'
        end
      end
    end
  end
end
