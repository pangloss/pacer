module Pacer
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jGraph
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge

  # Add 'static methods' to the Pacer namespace.
  class << self
    # Return a graph for the given path. Will create a graph if none exists at
    # that location. (The graph is only created if data is actually added to it).
    def neo4j(path)
      path = File.expand_path(path)
      return neo_graphs[path] if neo_graphs[path]
      graph = Neo4jGraph.new(path)
      neo_graphs[path] = graph
      register_neo_shutdown(path)
      graph
    end

    # Returns a hash of currently open neo graphs by path.
    def neo_graphs
      @neo_graphs ||= {}
    end

    protected

    # Registers the graph to be safely shut down when the program exits if
    # possible.
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


  # Extend the java class imported from blueprints.
  class Neo4jGraph
    include Routes::Base
    include Routes::RouteOperations
    include Routes::GraphRoute

    # Load and initialize a vertex by id.
    def vertex(id)
      if v = get_vertex(id)
        v.graph = self
        v
      end
    end

    # Load and initialize an edge by id.
    def edge(id)
      if e = get_edge(id)
        e.graph = self
        e
      end
    end

    # Discourage use of the native getVertex and getEdge methods
    protected :get_vertex, :getVertex, :get_edge, :getEdge
  end


  # Extend the java class imported from blueprints.
  class Neo4jVertex
    include Routes::VerticesRouteModule
    include ElementMixin
    include VertexMixin
  end


  # Extend the java class imported from blueprints.
  class Neo4jEdge
    include Routes::EdgesRouteModule
    include ElementMixin
    include EdgeMixin
  end
end
