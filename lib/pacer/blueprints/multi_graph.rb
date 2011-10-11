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

    def initialize(*args)
      super
      @vertex_keys = Set[]
      @join_keys = @vertex_keys
    end

    attr_accessor :vertex_keys, :join_keys

    def join_on(keys)
      if keys.is_a? Enumerable
        @join_keys = keys.map { |k| k.to_s }.to_set
      elsif keys
        @join_keys = Set[keys.to_s]
      else
        @join_keys = Set[]
      end
    end

    def vertices
      join_keys.flat_map do |key|
        @properties[key]
      end
    end

    def setProperty(key, value)
      if value.is_a? Pacer::Vertex
        vertex_keys << key.to_s
        super
      elsif value.is_a? Enumerable
        values = value.to_a
        if values.all? { |v| v.is_a? Pacer::Vertex }
          vertex_keys << key.to_s
        end
        super(key, values)
      else
        vertex_keys.delete key.to_s
        super
      end
    end

    def removeProperty(key)
      vertex_keys.delete key.to_s
      super
    end

    def getOutEdges(*labels)
      vs = vertices
      if vs.any?
        labels = extract_varargs_strings(labels)
        p = Pacer::Pipes::IdentityPipe.new
        p.setStarts(MultiIterator.new super(*labels), *vs.map { |v| v.getOutEdges(*labels).iterator })
        p
      else
        super
      end
    end

    def getInEdges(*labels)
      vs = vertices
      if vs.any?
        labels = extract_varargs_strings(labels)
        p = Pacer::Pipes::IdentityPipe.new
        p.setStarts MultiIterator.new super(*labels), *vs.map { |v| v.getInEdges(*labels).iterator }
        p
      else
        super
      end
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
