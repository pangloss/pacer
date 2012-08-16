module Pacer::Wrappers
  class WrapperSelector
    import com.tinkerpop.blueprints.Vertex
    import com.tinkerpop.blueprints.Edge

    def self.build(element_type, extensions = Set[])
      if element_type == :vertex
        Pacer::Wrappers::VertexWrapper.wrapper_for extensions
      elsif element_type == :edge
        Pacer::Wrappers::EdgeWrapper.wrapper_for extensions
      else
        new extensions
      end
    end

    attr_reader :extensions
    attr_accessor :vertex_wrapper, :edge_wrapper

    def initialize(extensions = Set[])
      @extensions = extensions
    end

    def wrapper(element)
      if element.is_a? Vertex
        self.vertex_wrapper ||= Pacer::Wrappers::VertexWrapper.wrapper_for extensions
      elsif element.is_a? Edge
        self.edge_wrapper ||= Pacer::Wrappers::EdgeWrapper.wrapper_for extensions
      end
    end

    def new(element)
      w = wrapper(element)
      if w
        w.new element
      else
        element
      end
    end
  end
end
