module Pacer
  import com.tinkerpop.blueprints.impls.tg.TinkerGraph
  import com.tinkerpop.blueprints.impls.tg.TinkerVertex
  import com.tinkerpop.blueprints.impls.tg.TinkerEdge
  import com.tinkerpop.blueprints.impls.tg.TinkerElement
  import com.tinkerpop.blueprints.impls.tg.TinkerIndex

  # Create a new TinkerGraph. If path is given, import the GraphML data from
  # the file specified.
  def self.tg(path = nil)
    if path
      PacerGraph.new TinkerGraph.new(path), SimpleEncoder
    else
      PacerGraph.new TinkerGraph.new, SimpleEncoder
    end
  end


  # Extend the java class imported from blueprints.
  class TinkerGraph

    def element_class
      TinkerElement
    end

    def vertex_class
      TinkerVertex
    end

    def edge_class
      TinkerEdge
    end
  end


  class TinkerIndex
    include IndexMixin
  end


  # Extend the java class imported from blueprints.
  class TinkerVertex
    include Pacer::Core::Graph::VerticesRoute
    include ElementMixin
    include VertexMixin
  end


  # Extend the java class imported from blueprints.
  class TinkerEdge
    include Pacer::Core::Graph::EdgesRoute
    include ElementMixin
    include EdgeMixin

    def in_vertex(extensions = nil)
      v = getVertex Pacer::Pipes::IN
      v.graph = graph
      if extensions.is_a? Enumerable
        v.add_extensions extensions
      elsif extensions
        v.add_extensions [extensions]
      else
        v
      end
    end

    def out_vertex(extensions = nil)
      v = getVertex Pacer::Pipes::OUT
      v.graph = graph
      if extensions.is_a? Enumerable
        v.add_extensions extensions
      elsif extensions
        v.add_extensions [extensions]
      else
        v
      end
    end
  end
end
