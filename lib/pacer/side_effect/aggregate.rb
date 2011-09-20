module Pacer
  module Routes::RouteOperations
    def aggregate
      chain_route :side_effect => :aggregate
    end
  end

  module SideEffect
    module Aggregate
      import com.tinkerpop.pipes.sideeffect.AggregatePipe

      protected

      def attach_pipe(end_pipe)
        pipe = AggregatePipe.new
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
