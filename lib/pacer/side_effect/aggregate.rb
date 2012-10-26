module Pacer
  module Routes::RouteOperations
    def aggregate(into = nil, &block)
      aggregate = ::Pacer::SideEffect::Aggregate
      r = self
      r = section(into, aggregate::ElementSet) if into.is_a? Symbol
      into = block if block
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
        case into
        when Symbol
          hs = vars[into] = HashSet.new
          pipe = AggregatePipe.new hs
        when Proc
          pipe = AggregatePipe.new into.call(self)
        when nil
          pipe = AggregatePipe.new HashSet.new
        else
          pipe = AggregatePipe.new into
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
