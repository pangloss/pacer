module Pacer::Core::Graph::ElementRoute
  def payload(&block)
    chain_route transform: :payload, block: block
  end
end

module Pacer::Transform
  module Payload
    attr_accessor :block

    protected

    def attach_pipe(end_pipe)
      pipe = PayloadPipe.new(self, block)
      pipe.setStarts end_pipe if end_pipe
      pipe
    end

    class PayloadPipe < Pacer::Pipes::RubyPipe
      field_reader :currentEnd

      attr_reader :block, :wrapper

      def initialize(route, block)
        super()
        if route.element_type == :edge
          @wrapper = Pacer::Payload::Edge
        elsif route.element_type == :vertex
          @wrapper = Pacer::Payload::Vertex
        else
          fail Pacer::ClientError, 'Can not use PayloadPipe on non-element data'
        end
        block ||= proc { |el| nil }
        @block = Pacer::Wrappers::WrappingPipeFunction.new route, block
      end

      def processNextStart
        el = starts.next
        @wrapper.new el, block.call(el)
      end

      def getPathToHere
        path = super
        i = path.size - 1
        path.remove path.size - 1 if i >= 0
        path.add currentEnd
        path
      end
    end
  end
end
