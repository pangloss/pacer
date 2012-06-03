module Pacer
  # This module is mixed into the raw Blueprints Edge class from any
  # graph implementation.
  #
  # Adds more convenient/rubyish methods and adds support for extensions
  # to some methods where needed.
  module EdgeMixin
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
        Wrappers::EdgeWrapper.wrap(self, exts)
      else
        self
      end
    end

    # The incoming vertex for this edge.
    # @return [Pacer::VertexMixin]
    def in_vertex(extensions = nil)
      v = getInVertex
      v.graph = graph
      if extensions
        v.add_extensions extensions
      else
        v
      end
    end

    def label
      getLabel
    end

    # The outgoing vertex for this edge.
    # @return [Pacer::VertexMixin]
    def out_vertex(extensions = nil)
      v = getOutVertex
      v.graph = graph
      if extensions
        v.add_extensions extensions
      else
        v
      end
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
      graph.removeEdge element
    end

    # Clones this edge into the target graph.
    #
    # This differs from the {#copy_into} in that it tries to set
    # the new element_id the same as the original element_id.
    #
    # @param [Pacer::GraphMixin] target_graph
    # @param [Hash] opts
    # @option opts :create_vertices [true] Create the vertices
    #   associated to this edge if they don't already exist.
    # @yield [e] Optional block yields the edge after it has been created.
    # @return [Pacer::EdgeMixin] the new edge
    #
    # @raise [StandardError] If this the associated vertices don't exist and :create_vertices is not set
    def clone_into(target_graph, opts = {})
      e_idx = target_graph.index_name("tmp:e:#{graph.to_s}", :edge, :create => true)
      e = target_graph.edge(element_id) || e_idx.get('id', element_id).first
      unless e
        v_idx = target_graph.index_name("tmp:v:#{graph.to_s}", :vertex, :create => true)
        iv = target_graph.vertex(in_vertex.element_id) || v_idx.get('id', in_vertex.element_id).first
        ov = target_graph.vertex(out_vertex.element_id) || v_idx.get('id', out_vertex.element_id).first
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
    # @param [Pacer::GraphMixin] target_graph
    # @yield [e] Optional block yields the edge after it has been created.
    # @return [Pacer::EdgeMixin] the new edge
    #
    # @raise [StandardError] If this the associated vertices don't exist
    def copy_into(target_graph)
      v_idx = target_graph.index_name("tmp:v:#{graph.to_s}", :vertex, :create => true)
      iv = v_idx.get('id', in_vertex.element_id).first || target_graph.vertex(in_vertex.element_id)
      ov = v_idx.get('id', out_vertex.element_id).first || target_graph.vertex(out_vertex.element_id)

      raise 'vertices not found' if not iv or not ov
      e = target_graph.create_edge nil, iv, ov, label, properties
      yield e if block_given?
      e
    end
  end
end
