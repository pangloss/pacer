module Pacer
  module Routes::RouteOperations
    def aggregate(into = nil)
      aggregate = ::Pacer::SideEffect::Aggregate
      r = self
      r = section(into, aggregate::ElementSet) if into.is_a? Symbol
      r.chain_route :side_effect => aggregate, :into => into
    end
  end

  module SideEffect
    module Aggregate
      import com.tinkerpop.pipes.sideeffect.AggregatePipe
      import java.util.HashSet

      include Pacer::Visitors::VisitsSection

      attr_reader :into

      def into=(name)
        @into = name
        self.section = name if name.is_a? Symbol
      end

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

      class ElementSet < HashSet
        def on_element(element)
          add element
        end

        def reset
          clear
        end
      end
    end
  end
end
