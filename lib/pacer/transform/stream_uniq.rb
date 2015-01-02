module Pacer
  module Routes::RouteOperations
    # Deprecated: use uniq_section instead.
    def stream_uniq(buffer = 1000)
      chain_route :transform => :stream_uniq, :buffer => buffer
    end
  end

  module Transform
    module StreamUniq
      attr_accessor :buffer

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::StreamUniqPipe.new buffer
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
