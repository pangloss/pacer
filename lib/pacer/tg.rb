module Pacer
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerGraph
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge

  def self.tg(path = nil)
    graph = TinkerGraph.new
    if path
      graph.import(path)
    end
    graph
  end


  class TinkerGraph
    include Routes::Base
    include Routes::RouteOperations
    include Routes::GraphRoute

    def vertex(id)
      if v = get_vertex(id)
        v.graph = self
        v
      end
    end

    def edge(id)
      if e = get_edge(id)
        e.graph = self
        e
      end
    end

    def get_vertices
      getVertices.to_a
    end

    def get_edges
      getEdges.to_a
    end
  end


  class TinkerVertex
    include Routes::VerticesRouteModule
    include ElementMixin
    include VertexMixin
  end


  class TinkerEdge
    include Routes::EdgesRouteModule
    include ElementMixin
    include EdgeMixin
  end
end
