module Pacer
  class RubyGraph
    import com.tinkerpop.blueprints.pgm.Element
    import com.tinkerpop.blueprints.pgm.Graph

    include Graph

    def initialize
      @graph_id = Pacer.next_graph_id
      clear
    end

    def element_class
      RubyElement
    end

    def vertex_class
      RubyVertex
    end

    def edge_class
      RubyEdge
    end

    def addVertex(id)
      if id
        id = "#{ graph_id }:#{ id }"
      else
        id = next_id
      end
      @vertices[id] = vertex_class.new self, id
    end

    def getVertex(id)
      @vertices[id]
    end

    def removeVertex(vertex)
      @vertices.delete vertex.element_id
    end

    def getVertices
      Pacer::Pipes::EnumerablePipe.new @vertices.values
    end

    def addEdge(id, outVertex, inVertex, label)
      id ||= next_id
      @edges[id] = edge_class.new self, id, outVertex, inVertex, label
    end

    def getEdge(id)
      @edges[id]
    end

    def removeEdge(edge)
      @edges.delete edge.element_id
    end

    def getEdges
      Pacer::Pipes::EnumerablePipe.new @edges.values
    end

    def clear
      @vertices = {}
      @edges = {}
      @next_id = 0
    end

    def shutdown
      clear
    end

    def ==(other)
      other.equal? self
    end

    include GraphExtensions

    private

    def next_id
      @next_id += 1
      "#{@graph_id}:#{@next_id}"
    end
  end

  class RubyElement
    include com.tinkerpop.blueprints.pgm.Element

    def initialize(graph, element_id)
      @graph = graph
      @element_id = element_id
      @properties = {}
    end

    def getPropertyKeys
      @properties.keys
    end

    def getProperty(key)
      v = @properties[key.to_s]
      if v.is_a? String
        v.dup
      else
        v
      end
    end

    def setProperty(key, value)
      @properties[key.to_s] = value
    end

    def removeProperty(key)
      @properties.delete key.to_s
    end

    def getId
      @element_id
    end

    protected

    def extract_varargs_strings(labels)
      if labels.first.is_a? ArrayJavaProxy
        labels.first.map { |l| l.to_s }
      else
        labels
      end
    end
  end


  class RubyVertex < RubyElement
    include com.tinkerpop.blueprints.pgm.Vertex

    def getRawVertex
      self
    end

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

    include VertexExtensions
  end

  class RubyEdge < RubyElement
    include com.tinkerpop.blueprints.pgm.Edge

    def initialize(graph, id, out_vertex, in_vertex, label)
      super(graph, id)
      @out_vertex = out_vertex
      @in_vertex = in_vertex
      @label = label.to_s
    end

    def getRawEdge
      self
    end

    def getLabel()
      @label
    end

    def getOutVertex()
      @out_vertex
    end

    def getInVertex()
      @in_vertex
    end

    include EdgeExtensions
  end
end
