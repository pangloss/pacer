module Pacer
  module Pipes
    class PathWrappingPipe < RubyPipe
      attr_reader :graph
      attr_accessor :vertex_wrapper, :edge_wrapper, :other_wrapper

      def initialize(graph, vertex_extensions = [], edge_extensions = [])
        super()
        @graph = graph
        @vertex_wrapper = Pacer::Wrappers::WrapperSelector.build :vertex, vertex_extensions || Set[]
        @edge_wrapper = Pacer::Wrappers::WrapperSelector.build :edge, edge_extensions || Set[]
      end

      def getCurrentPath
        starts.getCurrentPath
      end

      def processNextStart
        path = starts.next
        path.collect do |item|
          if item.is_a? Pacer::Vertex
            vertex_wrapper.new graph, item
          elsif item.is_a? Pacer::Edge
            edge_wrapper.new graph, item
          elsif other_wrapper
            other_wrapper.new graph, item
          else
            item
          end
        end
      end
    end
  end
end
