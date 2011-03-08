module Pacer
  module Routes
    module RouteOperations
      def map(opts = {}, &block)
        chain_route({:transform => :map, :block => block, :element_type => :object}.merge(opts))
      end
    end
  end

  module Transform
    module Map
      attr_accessor :block

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::MapPipe.new(back, block)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
