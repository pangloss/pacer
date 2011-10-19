module Pacer
  class ReplayGraph < RubyGraph
    attr_accessor :target_graph
    attr_reader :commands

    def initialize(target_graph = nil)
      super()
      @target_graph = target_graph
    end

    def addVertex(id)
      super.tap do |vertex|
        @commands << [nil, :addVertex, vertex.getId]
      end
    end

    def removeVertex(vertex)
      @commands << [nil, :removeVertex, vertex]
      super
    end

    def addEdge(id, outVertex, inVertex, label)
      super.tap do |edge|
        @commands << [nil, :addEdge, edge.element_id, edge.getOutVertex, edge.getInVertex, edge.getLabel]
      end
    end

    def removeEdge(edge)
      edge = edge.getRawEdge if edge.respond_to? :getRawEdge
      @commands << [nil, :removeEdge, edge.getRawEdge]
      super
    end

    def clear
      super
      @commands = []
    end

    def ==(other)
      other == @target_graph or super
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

  class ReplayVertex < ReplayElement
  end

  class ReplayEdge < ReplayElement
  end
end
