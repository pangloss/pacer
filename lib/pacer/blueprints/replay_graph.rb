module Pacer
  class ReplayGraph < RubyGraph
    attr_accessor :target_graph
    attr_reader :commands, :id_prefix

    def initialize(target_graph = nil)
      super()
      @graph_id = Pacer.next_graph_id
      @id_prefix = "#{ @graph_id }:".freeze
      @target_graph = target_graph
    end

    def addVertex(id)
      if id.is_a? String and id[0, id_prefix.length] == id_prefix
        v_id = id
      elsif id
        v_id = id_prefix + id.to_s
      else
        v_id = next_id
      end
      raise Pacer::ElementExists if @vertices.key? v_id
      vertex = @vertices[v_id] = vertex_class.new(self, v_id)
      commands << [nil, :addVertex, v_id]
      vertex
    end

    def getVertex(id)
      if id.is_a? String and id[0, id_prefix.length] == id_prefix
        @vertices[id]
      else
        @vertices[id_prefix + id.to_s]
      end
    end

    def removeVertex(vertex)
      commands << [nil, :removeVertex, vertex]
      super
    end

    def addEdge(id, outVertex, inVertex, label)
      super.tap do |edge|
        commands << [nil, :addEdge, edge.element_id, edge.getOutVertex, edge.getInVertex, edge.getLabel]
      end
    end

    def removeEdge(edge)
      edge = edge.getRawEdge if edge.respond_to? :getRawEdge
      commands << [nil, :removeEdge, edge.getRawEdge]
      super
    end

    def clear
      super
      @commands = []
    end

    def ==(other)
      (@target_graph and other == @target_graph) or super
    end

    protected

    def next_id
      id_prefix + super.to_s
    end
  end

  class ReplayElement < RubyElement
    def setProperty(key, value)
      @graph.commands << [self, :setProperty, key, value]
      super
    end

    def removeProperty(key)
      @graph.commands << [self, :removeProperty, key]
      super
    end
  end
end
