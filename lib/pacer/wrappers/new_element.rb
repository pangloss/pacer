module Pacer::Wrappers
  class NewElement
    include Pacer::Element

    def initialize
      @properties = {}
      @out_edges = []
      @in_edges = []
    end

    def getId
      nil
    end
    alias get_id getId

    def getPropertyKeys
      @properties.keys
    end
    alias property_keys getPropertyKeys

    def getProperty(prop)
      @properties[prop]
    end
    alias get_property getProperty

    def setProperty(prop, value)
      @properties[prop] = value
    end
    alias set_property setProperty

    def removeProperty(prop)
      @properties.delete prop
    end
    alias remove_property removeProperty

    def graph
      @graph
    end

    def graph=(graph)
      @graph = graph
    end

    def <=>(other)
      object_id <=> other.object_id
    end

    def ==(other)
      equal? other
    end
  end

  class NewVertex < NewElement
    include Pacer::Vertex

    def getOutEdges(*args)
      @out_edges
    end
    alias out_edges getOutEdges
    alias get_out_edges getOutEdges

    def getInEdges(*args)
      @in_edges
    end
    alias in_edges getInEdges
    alias get_in_edges getInEdges

    def getRawVertex
      self
    end
    alias raw_vertex getRawVertex
  end

  class NewEdge < NewElement
    include Pacer::Edge

    def getInVertex
      @in_vertex
    end
    alias in_vertex getInVertex
    alias inVertex getInVertex

    def getOutVertex
      @out_vertex
    end
    alias out_vertex getOutVertex
    alias outVertex getOutVertex

    def getLabel
      @label
    end
    alias get_label getLabel
    alias label getLabel

    def setLabel(label)
      @label = label
    end
    alias set_label setLabel
    alias label= setLabel

    def getRawEdge
      self
    end
    alias raw_edge getRawEdge
  end
end
