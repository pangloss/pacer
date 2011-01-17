module Pacer
  module EdgeMixin
    def add_extensions(exts)
      if exts.any?
        EdgeWrapper.wrap(self, exts)
      else
        self
      end
    end

    def in_vertex(extensions = nil)
      v = inVertex
      v.graph = graph
      if extensions
        v.add_extensions extensions
      else
        v
      end
    end

    def out_vertex(extensions = nil)
      v = outVertex
      v.graph = graph
      if extensions
        v.add_extensions extensions
      else
        v
      end
    end

    # Returns a human-readable representation of the edge.
    def inspect
      "#<E[#{element_id}]:#{display_name}>"
    end

    # Returns the display name of the vertex.
    def display_name
      if graph and graph.edge_name
        graph.edge_name.call self
      else
        "#{ out_vertex.element_id }-#{ get_label }-#{ in_vertex.element_id }"
      end
    end

    # Deletes the edge from its graph.
    def delete!
      graph.remove_edge element
    end

    def clone_into(target_graph, opts = {})
      e_idx = target_graph.index_name("tmp:e:#{graph.description}", :edge, :create => true)
      e = target_graph.edge(element_id) || e_idx.get('id', element_id).first
      unless e
        v_idx = target_graph.index_name("tmp:v:#{graph.description}", :vertex, :create => true)
        iv = target_graph.vertex(in_vertex.element_id) || v_idx.get('id', in_vertex.element_id).first
        ov = target_graph.vertex(out_vertex.element_id) || v_idx.get('id', out_vertex.element_id).first
        if opts[:create_vertices]
          iv ||= in_vertex.clone_into target_graph
          ov ||= out_vertex.clone_into target_graph
        end
        raise 'vertices not found' if not iv or not ov
        e = target_graph.create_edge(element_id, iv, ov, label, properties)
        e_idx.put('id', element_id, e)
        yield e if block_given?
      end
      e
    end

    def copy_into(target_graph, opts = {})
      v_idx = target_graph.index_name("tmp:v:#{graph.description}", :vertex, :create => true)
      iv = v_idx.get('id', in_vertex.element_id).first || target_graph.vertex(in_vertex.element_id)
      ov = v_idx.get('id', out_vertex.element_id).first || target_graph.vertex(out_vertex.element_id)

      raise 'vertices not found' if not iv or not ov
      e = target_graph.create_edge nil, iv, ov, label, properties
      yield e if block_given?
      e
    end
  end
end
