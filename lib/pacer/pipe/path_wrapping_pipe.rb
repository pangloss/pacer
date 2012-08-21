module Pacer
  module Pipes
    class PathWrappingPipe < RubyPipe
      attr_reader :graph
      attr_accessor :vertex_wrapper, :edge_wrapper, :other_wrapper

      def initialize(graph, vertex_extensions = [], edge_extensions = [])
        super()
        @graph = graph
        @vertex_wrapper = Pacer::Wrappers::WrapperSelector.build :vertex, vertex_extensions
        @edge_wrapper = Pacer::Wrappers::WrapperSelector.build :edge, edge_extensions
      end

      def processNextStart
        path = starts.next
        path.collect do |item|
          if item.is_a? Pacer::Vertex
            wrapped = vertex_wrapper.new item
            wrapped.graph = graph
            wrapped
          elsif item.is_a? Pacer::Edge
            wrapped = edge_wrapper.new item
            wrapped.graph = graph
            wrapped
          elsif other_wrapper
            wrapped = other_wrapper.new item
            wrapped.graph = graph if wrapped.respond_to? :graph
            wrapped
          else
            item
          end
        end
      rescue NativeException => e
        if e.cause.getClass == Pacer::NoSuchElementException.getClass
          raise e.cause
        else
          raise e
        end
      end
    end
  end
end
