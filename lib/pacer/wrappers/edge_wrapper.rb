module Pacer::Wrappers
  class EdgeWrapper < ElementWrapper
    include Pacer::Edge
    include Pacer::Core::Graph::EdgesRoute

    def_delegators :@element,
      :getId, :getLabel, :getPropertyKeys, :getProperty, :setProperty, :removeProperty,
      :getVertex,
      :getRawEdge

    class << self
      def wrapper_for(exts)
        @wrappers = {} unless defined? @wrappers
        if exts and not exts.empty?
          @wrappers[exts.to_set] ||= build_edge_wrapper(exts)
        else
          fail Pacer::LogicError, "Extensions should not be nil"
        end
      end

      def clear_cache
        @wrappers = {}
      end

      protected

      def build_edge_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Edge], EdgeWrapper)
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
      v = element.getVertex Pacer::Pipes::IN
      if extensions.is_a? Enumerable
        v = VertexWrapper.wrapper_for(extensions).new v
      elsif extensions
        v = VertexWrapper.wrapper_for(Set[extensions]).new v
      else
        v = VertexWrapper.new v
      end
      v.graph = graph
      v
    end

    # The outgoing vertex for this edge.
    # @return [Pacer::Wrappers::VertexWrapper]
    def out_vertex(extensions = nil)
      v = element.getVertex Pacer::Pipes::OUT
      if extensions.is_a? Enumerable
        v = VertexWrapper.wrapper_for(extensions).new v
      elsif extensions
        v = VertexWrapper.wrapper_for(Set[extensions]).new v
      else
        v = VertexWrapper.new v
      end
      v.graph = graph
      v
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
    # @see Core::Route#add_extension
    #
    # @param [[extensions]] exts the extensions to add
    # @return [Pacer::Wrappers::EdgeWrapper] this edge wrapped up and including
    #   the extensions
    def add_extensions(exts)
      if exts.any?
        e = self.class.wrap(element, extensions + exts.to_a)
        e.graph = graph
        e
      else
        self
      end
    end

    # Returns the element with a new simple wrapper.
    # @return [EdgeWrapper]
    def no_extensions
      EdgeWrapper.new element
    end

    # Returns a human-readable representation of the edge using the
    # standard ruby console representation of an instantiated object.
    # @return [String]
    def inspect
      "#<E[#{element_id}]:#{display_name}>"
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
    # @raise [StandardError] If this the associated vertices don't exist and :create_vertices is not set
    def clone_into(target_graph, opts = {})
      e_idx = target_graph.index("tmp:e:#{graph.to_s}", :edge, :create => true)
      e = target_graph.edge(element_id)
      unless e
        e = e_idx.first('id', element_id)
        if e
          e = EdgeWrapper.new(e)
          e.graph = target_graph
        end
      end
      unless e
        v_idx = target_graph.index("tmp:v:#{graph.to_s}", :vertex, :create => true)
        iv = target_graph.vertex(in_vertex.element_id) || v_idx.first('id', in_vertex.element_id)
        ov = target_graph.vertex(out_vertex.element_id) || v_idx.first('id', out_vertex.element_id)
        if opts[:create_vertices]
          iv ||= in_vertex.clone_into target_graph
          ov ||= out_vertex.clone_into target_graph
        end
        if not iv or not ov
          message = "Vertex not found for #{ self.inspect }: #{ iv.inspect } -> #{ ov.inspect }"
          puts message if opts[:show_missing_vertices]
          raise message unless opts[:ignore_missing_vertices]
          return nil
        end
        e = target_graph.create_edge(element_id, iv, ov, label, properties)
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
    # @raise [StandardError] If this the associated vertices don't exist
    def copy_into(target_graph)
      v_idx = target_graph.index("tmp:v:#{graph.to_s}", :vertex, :create => true)
      iv = v_idx.first('id', in_vertex.element_id) || target_graph.vertex(in_vertex.element_id)
      ov = v_idx.first('id', out_vertex.element_id) || target_graph.vertex(out_vertex.element_id)

      raise 'vertices not found' if not iv or not ov
      e = target_graph.create_edge nil, iv, ov, label, properties
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
    # @see #eql?
    # @param other
    def ==(other)
      other.is_a? EdgeWrapper and
        element_id == other.element_id and
        graph == other.graph
    end
  end
end
