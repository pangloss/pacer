module Pacer
  module VertexMixin
    def add_extension(mod)
      super
      if mod.const_defined? :Vertex
        extend mod::Vertex
        extensions << mod
      end
    end

    # Returns a human-readable representation of the vertex.
    def inspect
      "#<#{ ["V[#{get_id}]", display_name].compact.join(' ') }>"
    end

    # Returns the display name of the vertex.
    def display_name
      @graph.vertex_name.call self if @graph and @graph.vertex_name
    end

    # Deletes the vertex from its graph along with all related edges.
    def delete!
      @graph.remove_vertex self
    end

    def clone_into(target_graph, opts = {})
      return if target_graph.vertex(id)
      v = target_graph.add_vertex id
      properties.each do |name, value|
        v[name] = value
      end
      yield v if block_given?
      v
    end

    def copy_into(target_graph, opts = {})
      v = target_graph.add_vertex nil
      properties.each do |name, value|
        v[name] = value
      end
      yield v if block_given?
      v
    end
  end
end
