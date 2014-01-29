module Pacer::Wrappers
  class EdgeWrapper < ElementWrapper
    include Pacer::Edge
    include Pacer::Core::Graph::EdgesRoute

    def_delegators :@element,
      # Object
      :equals, :toString, :hashCode,
      # Element
      :getId, :getPropertyKeys, :getProperty, :setProperty, :removeProperty, :getRawElement,
      # Edge
      :getLabel, :getVertex, :getRawEdge

    class << self
      def wrappers
        @wrappers ||= {}
      end

      def wrapper_for(exts)
        if exts
          base_edge_wrapper.wrappers[exts] ||= build_edge_wrapper(exts)
        else
          fail Pacer::LogicError, "Extensions should not be nil"
        end
      end

      def clear_cache
        @wrappers = {}
      end

      protected

      def build_edge_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Edge], base_edge_wrapper)
      end
    end

    # This method must be defined here rather than in the superclass in order
    # to correctly override the method in an included module
    attr_reader :element

    def label
      getLabel
    end

    # The incoming vertex for this edge.
    # @return [Pacer::Wrappers::VertexWrapper]
    def in_vertex(extensions = nil)
      wrap_vertex element.getVertex(Pacer::Pipes::IN), extensions
    end

    # The outgoing vertex for this edge.
    # @return [Pacer::Wrappers::VertexWrapper]
    def out_vertex(extensions = nil)
      wrap_vertex element.getVertex(Pacer::Pipes::OUT), extensions
    end

    # This method must be defined here rather than in the superclass in order
    # to correctly override the method in an included module
    def extensions
      self.class.extensions
    end

    # Add extensions to this edge.
    #
    # If any extension has a Edge module within it, this edge will
    # be extended with the extension's Edge module.
    #
    # @param [[extensions]] exts the extensions to add
    # @return [Pacer::Wrappers::EdgeWrapper] this edge wrapped up and including
    #   the extensions
    def add_extensions(exts)
      if exts.any?
        self.class.wrap(self, extensions + exts.to_a)
      else
        self
      end
    end

    # Returns the element with a new simple wrapper.
    # @return [EdgeWrapper]
    def no_extensions
      self.class.base_edge_wrapper.new graph, element
    end

    # Returns a human-readable representation of the edge using the
    # standard ruby console representation of an instantiated object.
    # @return [String]
    def inspect
      graph.read_transaction do
        "#<E[#{element_id}]:#{display_name}>"
      end
    end

    # Returns the display name of the edge.
    # @return [String]
    def display_name
      if graph and graph.edge_name
        graph.edge_name.call self
      else
        "#{ out_vertex.element_id }-#{ getLabel }-#{ in_vertex.element_id }"
      end
    end

    # Deletes the edge from its graph.
    def delete!
      graph.remove_edge element
    end

    # Creates a new edge between the same elements with the same
    # properties, but in the opposite direction and optionally with a
    # new label. Attempts to reuse the edge id.
    def reverse!(opts = {})
      iv = out_vertex
      ov = in_vertex
      id = element_id if opts[:reuse_id]
      new_label = opts.fetch(:label, label)
      props = properties
      delete!
      graph.create_edge id, ov, iv, new_label, props
    end

    # Clones this edge into the target graph.
    #
    # This differs from the {#copy_into} in that it tries to set
    # the new element_id the same as the original element_id.
    #
    # @param [PacerGraph] target_graph
    # @param [Hash] opts
    # @option opts :create_vertices [true] Create the vertices
    #   associated to this edge if they don't already exist.
    # @yield [e] Optional block yields the edge after it has been created.
    # @return [Pacer::Wrappers::EdgeWrapper] the new edge
    #
    # @raise [Pacer::ElementNotFound] If this the associated vertices don't exist and :create_vertices is not set
    def clone_into(target_graph, opts = {})
      e_idx = target_graph.temp_index("tmp-e-#{graph.graph_id}", :edge, :create => true)
      e = e_idx.first('id', element_id)
      unless e
        v_idx = target_graph.temp_index("tmp-v-#{graph.graph_id}", :vertex, :create => true)
        iv = v_idx.first('id', in_vertex.element_id)
        ov = v_idx.first('id', out_vertex.element_id)
        if opts[:create_vertices]
          iv ||= in_vertex.clone_into target_graph
          ov ||= out_vertex.clone_into target_graph
        end
        if not iv or not ov
          message = "Vertex not found for #{ self.inspect }: #{ iv.inspect } -> #{ ov.inspect }"
          puts message if opts[:show_missing_vertices]
          fail Pacer::ElementNotFound, message unless opts[:ignore_missing_vertices]
          return nil
        end
        e = target_graph.create_edge(element_id, ov, iv, label, properties)
        e_idx.put('id', element_id, e)
        yield e if block_given?
      end
      e
    end

    # Copies this edge into the target graph with the next available
    # edge id.
    #
    # @param [PacerGraph] target_graph
    # @yield [e] Optional block yields the edge after it has been created.
    # @return [Pacer::Wrappers::EdgeWrapper] the new edge
    #
    # @raise [Pacer::ElementNotFound] If this the associated vertices don't exist
    def copy_into(target_graph)
      v_idx = target_graph.temp_index("tmp-v-#{graph.graph_id}", :vertex, :create => true)
      iv = v_idx.first('id', in_vertex.element_id) || target_graph.vertex(in_vertex.element_id)
      ov = v_idx.first('id', out_vertex.element_id) || target_graph.vertex(out_vertex.element_id)

      fail Pacer::ElementNotFound 'vertices not found' if not iv or not ov
      e = target_graph.create_edge nil, ov, iv, label, properties
      yield e if block_given?
      e
    end

    # Test equality to another object.
    #
    # Elements are equal if they are the same element type and have the same id
    # and the same graph, regardless of extensions/wrappers.
    #
    # If the graphdb instantiates multiple copies of the same element
    # this method will return true when comparing them.
    #
    # If the other instance is an unwrapped edge, this will always return
    # false because otherwise the == method would not be symetrical.
    #
    # @param other
    def ==(other)
      other.is_a? EdgeWrapper and
        element_id == other.element_id and
        graph == other.graph
    end
    alias eql? ==

    # Neo4j and Orient both have hash collisions between vertices and
    # edges which causes problems when making a set out of a path for
    # instance. Simple fix: negate edge hashes.
    def hash
      -element.hash
    end

    def element_payload=(data)
      if element.is_a? Pacer::Payload::Edge
        element.payload = data
      else
        @element = Pacer::Payload::Edge.new element, data
      end
    end

    private

    def wrap_vertex(v, extensions)
      if extensions.is_a? Enumerable
        if extensions.empty?
          self.class.base_vertex_wrapper.new graph, v
        else
          self.class.base_vertex_wrapper.wrapper_for(extensions).new graph, v
        end
      elsif extensions
        self.class.base_vertex_wrapper.wrapper_for([extensions]).new graph, v
      else
        self.class.base_vertex_wrapper.new graph, v
      end
    end
  end
end
