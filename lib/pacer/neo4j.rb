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
      raw_graph = graph.raw_graph
      def raw_graph.graph; @graph; end
      raw_graph.instance_variable_set '@graph', graph
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
    include Routes::GraphRoute

    alias vertex get_vertex
    alias edge get_edge

    # Discourage use of the native getVertex and getEdge methods
    protected :get_vertex, :getVertex, :get_edge, :getEdge
  end


  # Extend the java class imported from blueprints.
  class Neo4jVertex
    include Routes::VerticesRouteModule
    include ElementMixin
    include VertexMixin

    def graph
      raw_element.graph_database.graph
    end
  end


  # Extend the java class imported from blueprints.
  class Neo4jEdge
    include Routes::EdgesRouteModule
    include ElementMixin
    include EdgeMixin

    def graph
      raw_element.graph_database.graph
    end
  end
end
