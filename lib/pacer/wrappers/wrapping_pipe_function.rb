module Pacer
  module Wrappers
    class WrappingPipeFunction
      include com.tinkerpop.pipes.PipeFunction

      attr_reader :block, :graph, :wrapper, :extensions, :back

      def initialize(back, block)
        @back = back
        @block = block
        @graph = back.graph
        @extensions = back.extensions + [Pacer::Extensions::BlockFilterElement]
        @wrapper = WrapperSelector.build back.element_type, extensions
      end

      def compute(element)
        e = wrapper.new element
        e.graph = graph
        e.back = back
        block.call e
      end

      alias call compute
    end

    class UnwrappingPipeFunction
      include com.tinkerpop.pipes.PipeFunction

      attr_reader :block

      def initialize(block)
        @block = block
      end

      def compute(element)
        e = block.call element
        if e.is_a? ElementWrapper
          e.element
        else
          e
        end
      end

      alias call compute
    end
  end
end
