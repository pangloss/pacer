module Pacer
  class NewElement
    def initialize
      @properties = {}
      @out_edges = []
      @in_edges = []
    end

    def get_id
      nil
    end

    def property_keys
      @properties.keys
    end

    def get_property(prop)
      @properties[prop]
    end

    def set_property(prop, value)
      @properties[prop] = value
    end

    def remove_property(prop)
      @properties.delete prop
    end

    def out_edges
      @out_edges
    end

    def in_edges
      @in_edges
    end

    def raw_vertex
      self
    end

    def graph
      @graph
    end

    def graph=(graph)
      @graph = graph
    end

    def <=>(other)
      -1
    end

    def ==(other)
      equal? other
    end
  end
end
