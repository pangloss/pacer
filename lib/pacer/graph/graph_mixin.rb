module Pacer
  # Methods to be mixed into Blueprints Graph objects from any
  # implementation.
  #
  # Adds more convenient/rubyish methods and adds support for extensions
  # to some methods where needed.
  module GraphMixin
    def self.included(target)
      target.class_eval do
        protected :addVertex, :addEdge
        protected :add_vertex, :add_edge rescue nil
        protected :getVertex, :getEdge
        protected :get_vertex, :get_edge rescue nil
      end
    end

    attr_accessor :in_bulk_job

    def graph_id
      @graph_id = Pacer.next_graph_id unless defined? @graph_id
      @graph_id
    end

    # Get a vertex by id.
    #
    # @overload vertex(id)
    #   @param [element id] id
    # @overload vertex(id, *modules)
    #   @param [element id] id
    #   @param [Module, Class] *modules extensions to add to the returned
    #     vertex.
    def vertex(id, *modules)
      begin
        v = getVertex(id)
      rescue java.lang.RuntimeException
      end
      if v
        wrapper = modules.detect { |obj| obj.ancestors.include? Pacer::Wrappers::VertexWrapper }
        if wrapper
          v = wrapper.new v
          modules.delete wrapper
        end
        v.graph = self
        v.add_extensions modules
      else
        v
      end
    end

    # Get an edge by id.
    #
    # @overload edge(id)
    #   @param [element id] id
    # @overload edge(id, *modules)
    #   @param [element id] id
    #   @param [Module, Class] *modules extensions to add to the returned
    #     edge.
    def edge(id, *modules)
      begin
        v = getEdge(id)
      rescue Java::JavaLang::RuntimeException
      end
      if v
        wrapper = modules.detect { |obj| obj.ancestors.include? Pacer::Wrappers::EdgeWrapper }
        if wrapper
          v = wrapper.new v
          modules.delete wrapper
        end
        v.graph = self
        v.add_extensions modules
      end
    end

    # Create a vertex in the graph.
    #
    # @overload create_vertex(*args)
    #   @param [extension, Hash] *args extension (Module/Class) arguments will be
    #     added to the current vertex. A Hash will be
    #     treated as element properties.
    # @overload create_vertex(id, *args)
    #   @param [element id] id the desired element id. Some graphs
    #     ignore this.
    #   @param [extension, Hash] *args extension (Module/Class) arguments will be
    #     added to the current vertex. A Hash will be
    #     treated as element properties.
    def create_vertex(*args)
      id, wrapper, modules, props = id_modules_properties(args)
      vertex = creating_elements { addVertex(id) }
      vertex = wrapper.new vertex if wrapper
      vertex.graph = self
      props.each { |k, v| vertex[k.to_s] = v } if props
      if modules.any?
        vertex.add_extensions modules
      else
        vertex
      end
    end

    # Create an edge in the graph.
    #
    # @param [element id] id some graphs allow you to specify your own edge id.
    # @param [Pacer::VertexMixin] from_v the new edge's out_vertex
    # @param [Pacer::VertexMixin] to_v the new edge's in_vertex
    # @param [#to_s] label the edge label
    # @param [extension, Hash] *args extension (Module/Class) arguments will be
    #   added to the returned edge. A Hash will be
    #   treated as element properties.
    #
    # @todo make id param optional
    def create_edge(id, from_v, to_v, label, *args)
      _, wrapper, modules, props = id_modules_properties(args)
      edge = creating_elements { addEdge(id, from_v.element, to_v.element, label) }
      edge = wrapper.new edge if wrapper
      edge.graph = self
      props.each { |k, v| edge[k.to_s] = v } if props
      if modules.any?
        edge.add_extensions modules
      else
        edge
      end
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

    # Set how many elements should go into each transaction in a bulk
    # job.
    #
    # @param [Fixnum] size number of elements
    def bulk_job_size=(size)
      @bulk_job_size = size
    end

    # The currently configured bulk job size.
    def bulk_job_size
      if defined? @bulk_job_size
        @bulk_job_size
      else
        5000
      end
    end

    # Are we currently in the midst of a bulk job?
    def in_bulk_job?
      @in_bulk_job if defined? @in_bulk_job
    end

    # Directly loads an array of vertices by id.
    #
    # @param [[vertex ids]] ids
    # @return [[Pacer::VertexMixin]]
    def load_vertices(ids)
      ids.map do |id|
        vertex id
      end.compact
    end

    # Directly loads an array of edges by id.
    #
    # @param [[edge ids]] ids
    # @return [[Pacer::EdgeMixin]]
    def load_edges(ids)
      ids.map do |id|
        edge id
      end.compact
    end

    # The current graph
    #
    # @return [Graph] returns self
    def graph
      self
    end

    def equals(other)
      self == other
    end

    # The proc used to name vertices.
    #
    # @return [Proc]
    def vertex_name
      @vertex_name if defined? @vertex_name
    end

    # Set the proc used to name vertices.
    #
    # @param [Proc(vertex)] a_proc returns a string given a vertex
    def vertex_name=(a_proc)
      @vertex_name = a_proc
    end

    # The proc used to name edges.
    #
    # @return [Proc]
    def edge_name
      @edge_name if defined? @edge_name
    end

    # Set the proc used to name edges.
    #
    # @param [Proc(edge)] a_proc returns a string given an edge
    def edge_name=(a_proc)
      @edge_name = a_proc
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

    # Does this graph support edges where the in_vertex and the
    # out_vertex are the same?
    #
    # Specific graphs may override this method to return false.
    def supports_circular_edges?
      true
    end

    # When creating an element, does this graph allow me to specify the
    # element_id?
    #
    # Specific graphs may override this method to return false.
    def supports_custom_element_ids?
      true
    end

    # Does this graph allow me to create or modify automatic indices?
    #
    # Specific graphs may override this method to return false.
    def supports_automatic_indices?
      false
    end

    # Does this graph allow me to create or modify manual indices?
    #
    # Specific graphs may override this method to return false.
    def supports_manual_indices?
      false
    end

    # Does this graph support indices on edges?
    #
    # Specific graphs may override this method to return false.
    def supports_edge_indices?
      false
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

    def sanitize_properties(props)
      props
    end

    def encode_property(value)
      if value.is_a? String
        value = value.strip
        value unless value == ''
      else
        value
      end
    end

    def decode_property(value)
      value
    end

    def edges
      getEdges
    end

    protected

    # Helper method to wrap element creation in exception handling.
    def creating_elements
      begin
        yield
      rescue NativeException => e
        if e.message =~ /already exists/
          raise ElementExists, e.message
        else
          raise
        end
      end
    end

    def id_modules_properties(args)
      props = args.last if args.last.is_a? Hash
      modules = args.select { |obj| obj.is_a? Module or obj.is_a? Class }
      wrapper = modules.detect { |obj| obj.is_a? Class and obj.ancestors.include? Pacer::Wrappers::ElementWrapper }
      id = args.first
      if not wrapper and modules.empty?
        args.each do |obj|
          if obj.respond_to? :wrapper
            wrapper = obj.wrapper
            id = nil if id == obj
            break
          elsif obj.respond_to? :parts
            modules = obj.parts
            id = nil if id == obj
            break
          end
        end
      end
      modules.delete wrapper
      id = nil if id == props or modules.include? id or id == wrapper
      [id, wrapper, modules, props]
    end
  end
end
