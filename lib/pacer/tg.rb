module Pacer
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerGraph
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge

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
    include Routes::Base
    include Routes::GraphRoute

    alias vertex get_vertex
    alias edge get_edge

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

    alias original_add_edge addEdge
    def add_edge(*args)
      v = original_add_edge(*args)
      v.graph = self
      v
    end
    alias addEdge add_edge

    alias original_add_vertex addVertex
    def add_vertex(*args)
      v = original_add_vertex(*args)
      v.graph = self
      v
    end
    alias addVertex add_vertex
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
  end
end
