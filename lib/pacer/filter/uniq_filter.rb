module Pacer
  module Routes
    module RouteOperations
      # Do not return duplicate elements.
      def uniq(*filters, &block)
        Pacer::Route.property_filter_before(self, filters, block) do |r|
          chain_route :filter => :uniq
        end
      end
    end
  end

  module Filter
    module UniqFilter
      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::DuplicateFilterPipe.new
        pipe.set_starts(end_pipe)
        pipe
      end
    end
  end
end
