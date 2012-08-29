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
        # Must wrap based on parent pipe because the element in the block has
        # not yet been affected by any of this block's transforms.
        pf = Pacer::Wrappers::WrappingPipeFunction.new back || source, block
        pf = Pacer::Wrappers::UnwrappingPipeFunction.new pf
        pipe = com.tinkerpop.pipes.transform.TransformFunctionPipe.new pf
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
