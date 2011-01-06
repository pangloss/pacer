module Pacer
  module VertexMixin
    def add_extensions(exts)
      if exts.any?
        VertexWrapper.wrap(self, exts)
      else
        self
      end
    end

    # Returns a human-readable representation of the vertex.
    def inspect
      "#<#{ ["V[#{element_id}]", display_name].compact.join(' ') }>"
    end

    # Returns the display name of the vertex.
    def display_name
      graph.vertex_name.call self if graph and graph.vertex_name
    end

    # Deletes the vertex from its graph along with all related edges.
    def delete!
      graph.remove_vertex self
    end

    # Copies including the vertex id unless a vertex with that id
    # already exists.
    def clone_into(target_graph, opts = {})
      v_idx = target_graph.index_name("tmp:v:#{graph.description}", :vertex, :create => true)
      v = target_graph.vertex(element_id) || v_idx.get('id', element_id).first
      unless v
        v = target_graph.create_vertex element_id, properties
        v_idx.put('id', element_id, v)
        yield v if block_given?
      end
      v
    end

    # Make a new copy of the element with the next available vertex id.
    # @returns the new vertex
    def copy_into(target_graph, opts = {})
      v = target_graph.create_vertex, properties
      yield v if block_given?
      v
    end
  end
end
