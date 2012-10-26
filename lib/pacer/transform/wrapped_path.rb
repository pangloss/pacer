module Pacer
  module Core
    module Graph
      module PathRoute
        def wrapped(*exts)
          chain_route transform: :wrap_path, element_type: :path
        end
      end
    end
  end

  module Transform
    module WrapPath
      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::PathWrappingPipe.new(graph)
        pipe.setStarts end_pipe
        pipe
      end
    end
  end
end
