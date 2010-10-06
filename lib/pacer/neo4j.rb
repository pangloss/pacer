module Pacer
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jGraph
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge

  def self.neo4j(path)
    graph = Neo4jGraph.new(File.expand_path(path))
    at_exit do
      begin
        graph.shutdown
      rescue Exception, StandardError => e
        pp e
      end
    end
    graph
  end


  class Neo4jGraph
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
  end


  class Neo4jVertex
    include Routes::VerticesRouteModule
    include ElementMixin
    include VertexMixin
  end


  class Neo4jEdge
    include Routes::EdgesRouteModule
    include ElementMixin
    include EdgeMixin
  end
end
