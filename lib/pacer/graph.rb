module Pacer
  import com.tinkerpop.blueprints.pgm.Graph

  module Graph
    def import(path)
      path = File.expand_path path
      begin
        stream = java.net.URL.new(path).open_stream
      rescue java.net.MalformedURLException
        stream = java.io.FileInputStream.new path
      end
      com.tinkerpop.blueprints.pgm.parser.GraphMLReader.input_graph self, stream
      true
    end

    def export(path)
      path = File.expand_path path
      stream = new java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.pgm.parser.GraphMLWriter.outputGraph self, stream
    end
  end

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

    def out_v(*args)
      if args.any?
        super
      else
        out_vertex
      end
    end

    def in_v(*args)
      if args.any?
        super
      else
        in_vertex
      end
    end
  end


  module ElementMixin
    def self.included(target)
      target.send :include, Enumerable unless target.is_a? Enumerable
    end

    def graph=(graph)
      @graph = graph
    end

    def graph
      @graph
    end

    def [](key)
      get_property(key.to_s)
    end

    def []=(key, value)
      set_property(key.to_s, value)
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
