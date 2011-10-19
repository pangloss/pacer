module Pacer
  module Routes::RouteOperations
    def aggregate(into = nil)
      chain_route :side_effect => :aggregate, :into => into
    end
  end

  module SideEffect
    module Aggregate
      import com.tinkerpop.pipes.sideeffect.AggregatePipe
      import java.util.HashSet

      attr_accessor :into

      protected

      def attach_pipe(end_pipe)
        if into.is_a? Symbol
          hs = vars[into] = HashSet.new
          pipe = AggregatePipe.new hs
        elsif into
          pipe = AggregatePipe.new into
        else
          pipe = AggregatePipe.new HashSet.new
        end
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
