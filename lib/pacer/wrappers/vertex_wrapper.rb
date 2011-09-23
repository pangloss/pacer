module Pacer::Wrappers
  class VertexWrapper < ElementWrapper
    include Pacer::Vertex
    include Pacer::Core::Graph::VerticesRoute
    include Pacer::ElementMixin
    include Pacer::VertexMixin

    def_delegators :@element,
      :getId, :getPropertyKeys, :getProperty, :setProperty, :removeProperty,
      :getOutEdges, :getInEdges,
      :raw_vertex,
      :graph, :graph=, :<=>, :==

    class << self
      def wrapper_for(exts)
        @wrappers = {} unless defined? @wrappers
        @wrappers[exts.to_set] ||= build_vertex_wrapper(exts)
      end

      def clear_cache
        @wrappers = {}
      end

      protected

      def build_vertex_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Vertex], VertexWrapper)
      end
    end

    # This method must be defined here rather than in the superclass in order
    # to correctly override the method in an included module
    def extensions
      self.class.extensions
    end

    # This method must be defined here rather than in the superclass in order
    # to correctly override the method in an included module
    def element
      @element
    end
  end
end
