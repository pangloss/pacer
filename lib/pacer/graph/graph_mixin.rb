module Pacer
  # Methods to be mixed into Blueprints Graph objects from any
  # implementation.
  #
  # Adds more convenient/rubyish methods and adds support for extensions
  # to some methods where needed.
  module GraphMixin
    def blueprints_graph
      self
    end

    def graph_id
      @graph_id = Pacer.next_graph_id unless defined? @graph_id
      @graph_id
    end

    # Import the data in a GraphML file.
    #
    # Will fail if the data already exsts in the current graph.
    #
    # @param [String] path
    def import(path)
      path = File.expand_path path
      begin
        stream = java.net.URL.new(path).open_stream
      rescue java.net.MalformedURLException
        stream = java.io.FileInputStream.new path
      end
      creating_elements do
        com.tinkerpop.blueprints.util.io.graphml.GraphMLReader.input_graph self, stream
      end
      true
    ensure
      stream.close if stream
    end

    # Export the graph to GraphML
    #
    # @param [String] path will be replaced if it exists
    def export(path)
      path = File.expand_path path
      stream = java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.util.io.graphml.GraphMLWriter.outputGraph self, stream
    ensure
      stream.close if stream
    end

    # Is the element type given supported by this graph?
    #
    # @param [:edge, :vertex, :mixed, element_type, Object] et the
    #   object we're testing
    def element_type?(et)
      if [element_type(:vertex), element_type(:edge), element_type(:mixed)].include?  element_type(et)
        true
      else
        false
      end
    end

    def element_type(et = nil)
      return nil unless et
      result = if et == vertex_class or et == edge_class or et == element_class
        et
      else
        case et
        when :vertex, Pacer::Vertex, VertexMixin
          vertex_class
        when :edge, Pacer::Edge, EdgeMixin
          edge_class
        when :mixed, Pacer::Element, ElementMixin
          element_class
        when :object
          Object
        else
          if et == Object
            Object
          elsif vertex_class.respond_to? :java_class
            if et == vertex_class.java_class.to_java
              vertex_class
            elsif et == edge_class.java_class.to_java
              edge_class
            elsif et == Pacer::Vertex.java_class.to_java
              vertex_class
            elsif et == Pacer::Edge.java_class.to_java
              edge_class
            end
          end
        end
      end
      if result
        result
      else
        raise ArgumentError, 'Element type may be one of :vertex, :edge, :mixed or :object'
      end
    end

    def edges
      getEdges
    end

    protected

  end
end
