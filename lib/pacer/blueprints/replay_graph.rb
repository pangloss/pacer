module Pacer
  class ReplayGraph
    import com.tinkerpop.blueprints.pgm.Element
    import com.tinkerpop.blueprints.pgm.Graph

    include Graph

    class << self
      def next_graph_id
        @next_graph_id = 0 unless defined? @next_graph_id
        @next_graph_id += 1
      end
    end

    attr_accessor :target_graph
    attr_reader :commands

    def initialize(target_graph = nil)
      @graph_id = ReplayGraph.next_graph_id
      @target_graph = target_graph
      clear
    end

    def element_class
      ReplayElement
    end

    def vertex_class
      ReplayVertex
    end

    def edge_class
      ReplayEdge
    end

    def addVertex(id)
      id ||= next_id
      @commands << [nil, :addVertex, id]
      @vertices[id] = vertex_class.new self, id
    end

    def getVertex(id)
      @vertices[id]
    end

    def removeVertex(vertex)
      @commands << [nil, :removeVertex, vertex]
      @vertices.delete vertex.element_id
    end

    def getVertices
      @vertices.values
    end

    def addEdge(id, outVertex, inVertex, label)
      id ||= next_id
      @commands << [nil, :addEdge, id, outVertex, inVertex, label]
      @edges[id] = edge_class.new self, id, outVertex, inVertex, label
    end

    def getEdge(id)
      @edges[id]
    end

    def removeEdge(edge)
      @commands << [nil, :removeEdge, edge.raw_edge]
      @edges.delete edge.element_id
    end

    def getEdges
      @edges.values
    end

    def clear
      if defined? @vertices
        getEdges.each { |e| e.clear }
        getVertices.each { |v| v.clear }
      end
      @vertices = {}
      @edges = {}
      @commands = []
      @next_id = 0
    end

    def shutdown
      clear
    end

    def ==(other)
      other == @target_graph or other == self
    end

    include GraphExtensions

    private

    def next_id
      @next_id += 1
      "#{@graph_id}:#{@next_id}"
    end
  end

  class ReplayElement
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
      @properties[key]
    end

    def setProperty(key, value)
      @graph.commands << [self, :setProperty, key, value]
      @properties[key] = value
    end

    def removeProperty(key)
      @graph.commands << [self, :removeProperty, key]
      @properties.delete key
    end

    def getId
      @element_id
    end

  end


  class ReplayVertex < ReplayElement
    include com.tinkerpop.blueprints.pgm.Vertex

    def getRawVertex
      self
    end

    def getInEdges
      graph.getEdges.select { |e| e.getInVertex == self }
    end

    def getOutEdges
      graph.getEdges.select { |e| e.getOutVertex == self }
    end

    include VertexExtensions
  end

  class ReplayEdge < ReplayElement
    include com.tinkerpop.blueprints.pgm.Edge

    def initialize(graph, id, out_vertex, in_vertex, label)
      super(graph, id)
      @out_vertex = out_vertex
      @in_vertex = in_vertex
      @label = label
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
