module Pacer
  module Pipes
    class PathWrappingPipe < RubyPipe
      attr_reader :graph
      attr_accessor :vertex_wrapper, :edge_wrapper, :other_wrapper

      def initialize(graph, vertex_extensions = [], edge_extensions = [])
        super()
        if graph.is_a? Array
          @graph, @vertex_wrapper, @edge_wrapper = graph
        else
          @graph = graph
          @vertex_wrapper = Pacer::Wrappers::WrapperSelector.build graph, :vertex, vertex_extensions || Set[]
          @edge_wrapper = Pacer::Wrappers::WrapperSelector.build graph, :edge, edge_extensions || Set[]
        end
      end

      def instance(pipe, g)
        g ||= graph
        p = PathWrappingPipe.new [g, vertex_wrapper, edge_wrapper]
        p.setSterts pipe
        p
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
