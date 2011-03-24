module Pacer
  OrientGraph = com.tinkerpop.blueprints.pgm.impls.orientdb.OrientGraph
  OrientVertex = com.tinkerpop.blueprints.pgm.impls.orientdb.OrientVertex
  OrientEdge = com.tinkerpop.blueprints.pgm.impls.orientdb.OrientEdge
  OrientElement = com.tinkerpop.blueprints.pgm.impls.orientdb.OrientElement
  OrientIndex = com.tinkerpop.blueprints.pgm.impls.orientdb.OrientIndex

  class << self
    # for local graphs use orient("local:#{ path }")
    def orient(url, args = {})
      Pacer.starting_graph(self, url) do
        if args[:username]
          OrientGraph.new(url, args[:username], args[:password])
        else
          OrientGraph.new(url)
        end
      end
    end
  end

  class OrientGraph
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
      if et == OrientVertex or et == OrientEdge or et == OrientElement
        et
      else
        case et
        when :vertex, com.tinkerpop.blueprints.pgm.Vertex, VertexMixin
          OrientVertex
        when :edge, com.tinkerpop.blueprints.pgm.Edge, EdgeMixin
          OrientEdge
        when :mixed, com.tinkerpop.blueprints.pgm.Element, ElementMixin
          OrientElement
        when :object
          Object
        else
          if et == Object
            Object
          elsif et == OrientVertex.java_class.to_java
            OrientVertex
          elsif et == OrientEdge.java_class.to_java
            OrientEdge
          else
            raise ArgumentError, 'Element type may be one of :vertex or :edge'
          end
        end
      end
    end

    def sanitize_properties(props)
      props
    end

    def encode_property(value)
      if value.is_a? String
        value = value.strip
        value unless value == ''
      else
        value
      end
    end

    def decode_property(value)
      value
    end
  end


  class OrientIndex
    include IndexMixin
  end


  # Extend the java class imported from blueprints.
  class OrientVertex
    include Pacer::Core::Graph::VerticesRoute
    include ElementMixin
    include VertexMixin
  end


  # Extend the java class imported from blueprints.
  class OrientEdge
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
