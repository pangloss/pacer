module Pacer::Wrappers
  class EdgeWrapper < ElementWrapper
    include Pacer::Edge
    include Pacer::Core::Graph::EdgesRoute
    include Pacer::ElementMixin
    include Pacer::EdgeMixin

    def_delegators :@element,
      :getId, :getLabel, :getPropertyKeys, :getProperty, :setProperty, :removeProperty,
      :getVertex,
      :getRawEdge

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

    # This method must be defined here rather than in the superclass in order
    # to correctly override the method in an included module
    attr_reader :element

    def in_vertex(extensions = nil)
      v = element.getVertex Pacer::Pipes::IN
      if extensions.is_a? Enumerable
        v = VertexWrapper.wrapper_for(extensions).new v
      elsif extensions
        v = VertexWrapper.wrapper_for(Set[extensions]).new v
      else
        v = VertexWrapper.new v
      end
      v.graph = graph
      v
    end

    def out_vertex(extensions = nil)
      v = element.getVertex Pacer::Pipes::OUT
      if extensions.is_a? Enumerable
        v = VertexWrapper.wrapper_for(extensions).new v
      elsif extensions
        v = VertexWrapper.wrapper_for(Set[extensions]).new v
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

    def add_extensions(exts)
      if exts.any?
        e = self.class.wrap(element, extensions + exts.to_a)
        e.graph = graph
        e
      else
        self
      end
    end
  end
end
