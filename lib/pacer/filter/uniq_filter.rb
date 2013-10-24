module Pacer
  module Routes
    module RouteOperations
      import com.tinkerpop.pipes.filter.DuplicateFilterPipe
      import com.tinkerpop.pipes.filter.CyclicPathFilterPipe

      # Do not return duplicate elements.
      def uniq
        chain_route :pipe_class => DuplicateFilterPipe, :route_name => 'uniq'
      end

      # Filter out any element where its path would contain the same element twice.
      def unique_path
        chain_route :pipe_class => CyclicPathFilterPipe, :route_name => 'unique_path'
      end
    end
  end
end
