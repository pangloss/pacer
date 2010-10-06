module Pacer
  import com.tinkerpop.blueprints.pgm.Graph;


  module VertexMixin
    def inspect
      "#<#{ ["V[#{id}]", name].compact.join(' ') }>"
    end

    def name
      graph.vertex_name.call self if graph and graph.vertex_name
    end

    def delete!
      graph.remove_vertex self
    end
  end


  module EdgeMixin
    def inspect
      "#<E[#{id}]:#{ out_vertex.id }-#{ get_label }-#{ in_vertex.id }>"
    end

    def delete!
      graph.remove_edge self
    end
  end


  module ElementMixin
    def graph=(graph)
      @graph = graph
    end

    def graph
      @graph
    end

    def [](key)
      get_property(key.to_s)
    end

    def result(name = nil)
      self
    end

    def from_graph?(graph)
      if @graph
        @graph == graph
      elsif graph.raw_graph == raw_vertex.graph_database
        @graph = graph
        true
      end
    end

    def properties
      property_keys.inject({}) { |h, k| h[k] = get_property(k); h }
    end

    def name
      id
    end
  end
end
