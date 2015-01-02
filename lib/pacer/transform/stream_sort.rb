module Pacer
  module Routes::RouteOperations
    # Deprecated: use sort_section instead.
    def stream_sort(buffer = 1000, silo = 100)
      chain_route :transform => :stream_sort, :buffer => buffer, :silo => silo
    end
  end

  module Transform
    module StreamSort
      attr_accessor :buffer, :silo

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::StreamSortPipe.new buffer, silo
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
