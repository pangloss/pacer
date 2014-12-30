module Pacer
  module Pipes
    class WrappingPipe < RubyPipe
      attr_reader :graph, :element_type, :extensions, :wrapper

      def initialize(graph, element_type = nil, extensions = [])
        super()
        if graph.is_a? Array
          @graph, @wrapper = graph
        else
          @graph = graph
          @element_type = element_type
          @extensions = extensions || []
          @wrapper = Pacer::Wrappers::WrapperSelector.build graph, element_type, @extensions
        end
      end

      def instance(pipe, g)
        g ||= graph
        p = WrappingPipe.new [g, wrapper]
        p.setStarts pipe
        p
      end

      def getSideEffect
        starts.getSideEffect
      end

      def getCurrentPath
        starts.getCurrentPath
      end

      def wrapper=(w)
        if extensions.any? and w.respond_to? :add_extensions
          @wrapper = w.add_extensions extensions
        else
          @wrapper = w
        end
      end

      def processNextStart
        wrapper.new graph, starts.next
      end
    end
  end
end
