module Pacer
  class VertexWrapper < ElementWrapper
    include Pacer::Core::Graph::VerticesRoute
    include ElementMixin
    include VertexMixin
    include Comparable

    def_delegators :@element,
      :property_keys, :get_property, :set_property, :remove_property,
      :out_edges, :in_edges,
      :raw_vertex,
      :graph, :graph=, :<=>, :==

    class << self
      def wrapper_for(exts)
        @wrappers ||= {}
        @wrappers[exts] ||= build_vertex_wrapper(exts)
      end

      protected

      def build_vertex_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Vertex], VertexWrapper)
      end
    end

    def extensions
      self.class.extensions
    end

    def element
      @element
    end
  end
end
