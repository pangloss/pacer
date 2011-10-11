module Pacer
  class MultiGraph < RubyGraph
    def element_class
      RubyElement
    end

    def vertex_class
      MultiVertex
    end

    def edge_class
      MultiEdge
    end
  end


  class MultiVertex < RubyVertex
    import com.tinkerpop.pipes.util.MultiIterator

    attr_accessor :vertices

    def initialize(*args)
      super
      @vertices = []
    end

    def add_vertex(vertex)
      @vertices << vertex
    end

    def getOutEdges(*labels)
      labels = extract_varargs_strings(labels)
      p = Pacer::Pipes::IdentityPipe.new
      p.setStarts(MultiIterator.new super(*labels), *@vertices.map { |v| v.getOutEdges(*labels).iterator })
      p
    end

    def getInEdges(*labels)
      labels = extract_varargs_strings(labels)
      p = Pacer::Pipes::IdentityPipe.new
      p.setStarts MultiIterator.new super(*labels), *@vertices.map { |v| v.getInEdges(*labels).iterator }
      p
    end

    include VertexExtensions
  end

  class MultiEdge < RubyEdge
    include com.tinkerpop.blueprints.pgm.Vertex

    def getInEdges(*labels)
      labels = extract_varargs_strings(labels)
      edges = graph.getEdges.select { |e| e.getInVertex == self and (labels.empty? or labels.include? e.getLabel) }
      Pacer::Pipes::EnumerablePipe.new edges
    end

    def getOutEdges(*labels)
      labels = extract_varargs_strings(labels)
      edges = graph.getEdges.select { |e| e.getOutVertex == self and (labels.empty? or labels.include? e.getLabel) }
      Pacer::Pipes::EnumerablePipe.new edges
    end

    def inspect
      "#<E[#{element_id}]:#{display_name}>"
    end

    def display_name
      if graph and graph.edge_name
        graph.edge_name.call self
      else
        "#{ out_vertex.element_id }-#{ getLabel }-#{ in_vertex.element_id }"
      end
    end
    include VertexExtensions
    include EdgeExtensions
  end
end
