module Pacer
  module Wrappers
    class WrappingPipeFunction
      include com.tinkerpop.pipes.PipeFunction

      attr_reader :block, :graph, :wrapper, :extensions, :back

      def initialize(back, block)
        @back = back
        @block = block
        if back
          @graph = back.graph
          @extensions = back.extensions + [Pacer::Extensions::BlockFilterElement]
          element_type = back.element_type
        end
        @wrapper = WrapperSelector.build element_type, extensions
      end

      def arity
        block.arity
      end

      def compute(element)
        e = wrapper.new element
        e.graph = graph if e.respond_to? :graph=
        e.back = back if e.respond_to? :back=
        block.call e
      end

      alias call compute

      def call_with_args(element, *args)
        e = wrapper.new element
        e.graph = graph if e.respond_to? :graph=
        e.back = back if e.respond_to? :back=
        block.call e, *args
      end

      def wrap_path(path)
        path.collect do |item|
          if item.is_a? Pacer::Vertex
            wrapped = Pacer::Wrappers::VertexWrapper.new item
            wrapped.graph = graph
            wrapped
          elsif item.is_a? Pacer::Edge
            wrapped = Pacer::Wrappers::EdgeWrapper.new item
            wrapped.graph = graph
            wrapped
          else
            item
          end
        end
      end
    end

    class UnwrappingPipeFunction
      include com.tinkerpop.pipes.PipeFunction

      attr_reader :block

      def initialize(block)
        @block = block
      end

      def arity
        block.arity
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

      def call_with_args(element, *args)
        e = block.call element, *args
        if e.is_a? ElementWrapper
          e.element
        else
          e
        end
      end
    end
  end
end
