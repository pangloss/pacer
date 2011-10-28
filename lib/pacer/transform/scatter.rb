module Pacer
  module Core
    module Route
      def scatter(args = {})
        chain_route({transform: :scatter, element_type: :object}.merge(args))
      end
    end
  end

  module Transform
    module Scatter
      import com.tinkerpop.pipes.transform.ScatterPipe

      protected

      def attach_pipe(end_pipe)
        pipe = ScatterPipe.new
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
