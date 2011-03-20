require 'yaml'

module Pacer
  Neo4jGraph = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jGraph
  Neo4jVertex = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
  Neo4jEdge = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge
  Neo4jElement = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jElement
  Neo4jIndex = com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jIndex

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
    include GraphMixin
    include GraphTransactionsMixin
    include ManagedTransactionsMixin
    include Pacer::Core::Route
    include Pacer::Core::Graph::GraphRoute

    # Override to return an enumeration-friendly array of vertices.
    def get_vertices
      getVertices.to_route(:graph => self, :element_type => :vertex)
    end

    # Override to return an enumeration-friendly array of edges.
    def get_edges
      getEdges.to_route(:graph => self, :element_type => :edge)
    end

    def element_type(et = nil)
      return nil unless et
      if et == Neo4jVertex or et == Neo4jEdge or et == Neo4jElement
        et
      else
        case et
        when :vertex, com.tinkerpop.blueprints.pgm.Vertex, VertexMixin
          Neo4jVertex
        when :edge, com.tinkerpop.blueprints.pgm.Edge, EdgeMixin
          Neo4jEdge
        when :mixed, com.tinkerpop.blueprints.pgm.Element, ElementMixin
          Neo4jElement
        when :object
          Object
        else
          if et == Object
            Object
          elsif et == Neo4jVertex.java_class.to_java
            Neo4jVertex
          elsif et == Neo4jEdge.java_class.to_java
            Neo4jEdge
          else
            raise ArgumentError, 'Element type may be one of :vertex or :edge'
          end
        end
      end
    end

    def sanitize_properties(props)
      pairs = props.map do |name, value|
        [name, encode_property(value)]
      end
      Hash[pairs]
    end

    def encode_property(value)
      case value
      when nil
        nil
      when String
        value = value.strip
        value = nil if value == ''
        value
      when Numeric
        if value.is_a? Bignum
          value.to_yaml
        else
          value
        end
      else
        value.to_yaml
      end
    end

    def decode_property(value)
      if value.is_a? String and value[0, 3] == '---'
        YAML.load(value)
      else
        value
      end
    end
  end


  class Neo4jIndex
    include IndexMixin
  end


  # Extend the java class imported from blueprints.
  class Neo4jVertex
    include Pacer::Core::Graph::VerticesRoute
    include ElementMixin
    include VertexMixin
  end


  # Extend the java class imported from blueprints.
  class Neo4jEdge
    include Pacer::Core::Graph::EdgesRoute
    include ElementMixin
    include EdgeMixin

    def in_vertex(extensions = nil)
      v = inVertex
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
      v = outVertex
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
