module Pacer::Wrappers
  class WrapperSelector
    import com.tinkerpop.blueprints.Vertex
    import com.tinkerpop.blueprints.Edge

    def self.build(graph, element_type = nil, extensions = [])
      if graph
        if element_type == :vertex
          graph.base_vertex_wrapper.wrapper_for extensions
        elsif element_type == :edge
          graph.base_edge_wrapper.wrapper_for extensions
        else
          new extensions
        end
      else
        if element_type == :vertex
          Pacer::Wrappers::VertexWrapper.wrapper_for extensions
        elsif element_type == :edge
          Pacer::Wrappers::EdgeWrapper.wrapper_for extensions
        else
          new extensions
        end
      end
    end

    attr_reader :extensions
    attr_accessor :vertex_wrapper, :edge_wrapper

    def initialize(extensions = [])
      @extensions = extensions
    end

    def wrapper(graph, element)
      if graph
        if element.is_a? Vertex
          self.vertex_wrapper ||= graph.base_vertex_wrapper.wrapper_for extensions
        elsif element.is_a? Edge
          self.edge_wrapper ||= graph.base_edge_wrapper.wrapper_for extensions
        end
      else
        if element.is_a? Vertex
          self.vertex_wrapper ||= Pacer::Wrappers::VertexWrapper.wrapper_for extensions
        elsif element.is_a? Edge
          self.edge_wrapper ||= Pacer::Wrappers::EdgeWrapper.wrapper_for extensions
        end
      end
    end

    def new(graph, element)
      w = wrapper(graph, element)
      if w
        w.new graph, element
      else
        element
      end
    end
  end
end
