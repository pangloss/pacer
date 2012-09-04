module Pacer
  module Pipes
    class WrappingPipe < RubyPipe
      attr_reader :graph, :element_type, :extensions, :wrapper

      def initialize(graph, element_type = nil, extensions = [])
        super()
        @graph = graph
        @element_type = element_type
        @extensions = extensions || []
        @wrapper = Pacer::Wrappers::WrapperSelector.build element_type, @extensions
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
        e = wrapper.new starts.next
        if element_type == :vertex or element_type == :edge or element_type == :mixed
          e.graph = graph
        elsif e.respond_to? :graph=
          e.graph = graph
        end
        e
      end
    end
  end
end
