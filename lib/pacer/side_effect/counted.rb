module Pacer
  module Routes
    module RouteOperations
      def counted
        chain_route :side_effect => :counted
      end

      def count
        counted.count
      end
      alias run! count
    end
  end


  module SideEffect
    module Counted
      def count
        cap.first
      end

      protected

      def attach_pipe(end_pipe)
        @pipe = com.tinkerpop.pipes.sideeffect.CountPipe.new
        @pipe.setStarts(end_pipe) if end_pipe
        @pipe
      end
    end
  end
end
