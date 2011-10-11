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
        @commands << [nil, :addEdge, edge.id, edge.outVertex, edge.inVertex, edge.getLabel]
      end
    end

    def removeEdge(edge)
      @commands << [nil, :removeEdge, edge.raw_edge]
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
