module Pacer
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerGraph
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerIndex

  # Create a new TinkerGraph. If path is given, import the GraphML data from
  # the file specified.
  def self.tg(path = nil)
    graph = TinkerGraph.new
    if path
      graph.import(path)
    end
    graph
  end


  # Extend the java class imported from blueprints.
  class TinkerGraph
    include GraphMixin
    include GraphTransactionsStub
    include ManagedTransactionsMixin
    include Routes::Base
    include Routes::GraphRoute

    # Override to return an enumeration-friendly array of vertices.
    def get_vertices
      getVertices.to_a
    end

    # Override to return an enumeration-friendly array of edges.
    def get_edges
      getEdges.to_a
    end

    def ==(other)
      other.class == self.class and other.object_id == self.object_id
    end

    def element_type(et)
      case et
      when :vertex, com.tinkerpop.blueprints.pgm.Vertex, VertexMixin
        TinkerVertex
      when :edge, com.tinkerpop.blueprints.pgm.Edge, EdgeMixin
        TinkerEdge
      else
        raise ArgumentError, 'Element type may be one of :vertex or :edge'
      end
    end

    def sanitize_properties(props)
      props
    end
  end


  class TinkerIndex
    include IndexMixin
  end


  # Extend the java class imported from blueprints.
  class TinkerVertex
    include Routes::VerticesRouteModule
    include ElementMixin
    include VertexMixin
  end


  # Extend the java class imported from blueprints.
  class TinkerEdge
    include Routes::EdgesRouteModule
    include ElementMixin
    include EdgeMixin

    def in_vertex(extensions = nil)
      v = inVertex
      v.graph = graph
      if extensions
        v.add_extensions extensions
      else
        v
      end
    end

    def out_vertex(extensions = nil)
      v = outVertex
      v.graph = graph
      if extensions
        v.add_extensions extensions
      else
        v
      end
    end

  end
end
