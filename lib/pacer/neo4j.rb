module Pacer
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jGraph
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge

  class << self
    def neo4j(path)
      path = File.expand_path(path)
      return neo_graphs[path] if neo_graphs[path]
      graph = Neo4jGraph.new(path)
      neo_graphs[path] = graph
      register_neo_shutdown(path)
      graph
    end

    def neo_graphs
      @neo_graphs ||= {}
    end

    def register_neo_shutdown(path)
      at_exit do
        begin
          neo_graphs[path].shutdown if neo_graphs[path]
        rescue Exception, StandardError => e
          pp e
        end
      end
    end
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
