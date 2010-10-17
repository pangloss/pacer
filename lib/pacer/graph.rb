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
      stream = java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.pgm.parser.GraphMLWriter.outputGraph self, stream
    end
  end

  module VertexMixin

    # Returns a human-readable representation of the vertex.
    def inspect
      "#<#{ ["V[#{id}]", display_name].compact.join(' ') }>"
    end

    # Returns the display name of the vertex.
    def display_name
      graph.vertex_name.call self if graph and graph.vertex_name
    end

    # Deletes the vertex from its graph along with all related edges.
    def delete!
      graph.remove_vertex self
    end
  end


  module EdgeMixin

    # Returns a human-readable representation of the edge.
    def inspect
      "#<E[#{id}]:#{display_name}>"
    end

    # Returns the display name of the vertex.
    def display_name
      if graph and graph.edge_name
        graph.edge_name.call self
      else
        "#{ out_vertex.id }-#{ get_label }-#{ in_vertex.id }"
      end
    end

    # Deletes the edge from its graph.
    def delete!
      graph.remove_edge self
    end

    # Returns a path if arguments are given, otherwise returns the out vertex
    # itself.
    def out_v(*args)
      if args.any?
        super
      else
        out_vertex
      end
    end

    # Returns a path if arguments are given, otherwise returns the in vertex
    # itself.
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

    # Specify the graph the element belongs to. For internal use only.
    def graph=(graph)
      @graph = graph
    end

    # The graph the element belongs to. Used to help prevent objects from
    # different graphs from being accidentally associated, as well as to get
    # graph-specific data for the element.
    def graph
      @graph
    end

    # Convenience method to retrieve a property by name.
    def [](key)
      get_property(key.to_s)
    end

    # Convenience method to set a property by name to the given value.
    def []=(key, value)
      set_property(key.to_s, value)
    end

    # Specialize result to return self for elements.
    def result(name = nil)
      self
    end

    # Query whether the current node belongs to the given graph.
    def from_graph?(graph)
      if @graph
        @graph == graph
      elsif graph.raw_graph == raw_vertex.graph_database
        @graph = graph
        true
      end
    end

    # Returns a hash of property values by name.
    def properties
      property_keys.inject({}) { |h, name| h[name] = get_property(name); h }
    end

    # Returns a basic display name for the element. This method should be specialized.
    def display_name
      id
    end

    # Yields the element once or returns an enumerator containing self if no
    # block is given. Follows Ruby conventions and is meant to be used along
    # with the Enumerable mixin.
    def each
      if block_given?
        yield self
      else
        [self].to_enum
      end
    end
  end
end

require 'pacer/graph/transactions'
