module Pacer
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerGraph
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge
  import com.tinkerpop.blueprints.pgm.impls.tg.TinkerElement
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
    include GraphIndicesMixin
    include GraphTransactionsStub
    include ManagedTransactionsMixin
    include Pacer::Core::Route
    include Pacer::Core::Graph::GraphRoute
    include Pacer::Core::Graph::GraphIndexRoute

    def element_class
      TinkerElement
    end

    def vertex_class
      TinkerVertex
    end

    def edge_class
      TinkerEdge
    end

    # Override to return an enumeration-friendly array of vertices.
    def get_vertices
      getVertices.iterator.to_route(:graph => self, :element_type => :vertex)
    end

    # Override to return an enumeration-friendly array of edges.
    def get_edges
      getEdges.iterator.to_route(:graph => self, :element_type => :edge)
    end

    def ==(other)
      other.class == self.class and other.object_id == self.object_id
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
