module Pacer
  class MultiGraph < RubyGraph
    def element_class
      RubyElement
    end

    def vertex_class
      MultiVertex
    end

    def edge_class
      RubyEdge
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
      case value
      when Pacer::Vertex
        vertex_keys << key.to_s
        super
      when Hash
        vertex_keys.delete key.to_s
        super
      when Enumerable
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
end
