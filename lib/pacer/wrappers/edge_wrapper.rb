module Pacer::Wrappers
  class EdgeWrapper < ElementWrapper
    include Pacer::Core::Graph::EdgesRoute
    include Pacer::ElementMixin
    include Pacer::EdgeMixin
    include Comparable

    def_delegators :@element,
      :label, :get_label, :property_keys, :get_property, :set_property, :remove_property,
      :in_vertex, :out_vertex,
      :raw_edge,
      :graph, :graph=, :<=>, :==

    class << self
      def wrapper_for(exts)
        @wrappers ||= {}
        @wrappers[exts] ||= build_edge_wrapper(exts)
      end

      protected

      def build_edge_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Edge], EdgeWrapper)
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
