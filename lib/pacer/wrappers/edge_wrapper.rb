module Pacer::Wrappers
  class EdgeWrapper < ElementWrapper
    include Pacer::Edge
    include Pacer::Core::Graph::EdgesRoute
    include Pacer::ElementMixin
    include Pacer::EdgeMixin

    def_delegators :@element,
      :getId, :getLabel, :getPropertyKeys, :getProperty, :setProperty, :removeProperty,
      :getVertex,
      :getRawEdge,
      :<=>, :==

    class << self
      def wrapper_for(exts)
        @wrappers = {} unless defined? @wrappers
        @wrappers[exts.to_set] ||= build_edge_wrapper(exts)
      end

      def clear_cache
        @wrappers = {}
      end

      protected

      def build_edge_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Edge], EdgeWrapper)
      end
    end

    def in_vertex(extensions = nil)
      v = element.getVertex Pacer::Pipes::IN
      if extensions.is_a? Enumerable
        v = v.add_extensions extensions
      elsif extensions
        v = v.add_extensions [extensions]
      else
        v = VertexWrapper.new v
      end
      v.graph = graph
      v
    end

    def out_vertex(extensions = nil)
      v = element.getVertex Pacer::Pipes::OUT
      if extensions.is_a? Enumerable
        v = v.add_extensions extensions
      elsif extensions
        v = v.add_extensions [extensions]
      else
        v = VertexWrapper.new v
      end
      v.graph = graph
      v
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

    def add_extensions(exts)
      if exts.any?
        self.class.wrap(element, extensions + exts.to_a)
      else
        self
      end
    end
  end
end
