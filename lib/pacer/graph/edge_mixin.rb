module Pacer
  module EdgeMixin
    def add_extension(mod)
      super
      if mod.const_defined? :Edge
        extend mod::Edge
        extensions << mod
      end
    end

    # Returns a human-readable representation of the edge.
    def inspect
      "#<E[#{get_id}]:#{display_name}>"
    end

    # Returns the display name of the vertex.
    def display_name
      if @graph and @graph.edge_name
        @graph.edge_name.call self
      else
        "#{ out_vertex.get_id }-#{ get_label }-#{ in_vertex.get_id }"
      end
    end

    # Deletes the edge from its graph.
    def delete!
      @graph.remove_edge self
    end

    # Returns a path if arguments are given, otherwise returns the out vertex
    # itself.
    def out_v(*args)
      if args.any?
        super
      else
        v = out_vertex
        v.graph = graph
        v
      end
    end

    # Returns a path if arguments are given, otherwise returns the in vertex
    # itself.
    def in_v(*args)
      if args.any?
        super
      else
        v = in_vertex
        v.graph = graph
        v
      end
    end

    def clone_into(target_graph, opts = {})
      return if target_graph.edge(get_id)
      iv = target_graph.vertex(in_v.get_id)
      ov = target_graph.vertex(out_v.get_id)
      if opts[:create_vertices]
        iv ||= in_v.clone_into target_graph
        ov ||= out_v.clone_into target_graph
      end
      return if not iv or not ov
      e = target_graph.create_edge get_id, iv, ov, label
      properties.each do |name, value|
        e[name] = value
      end
      yield e if block_given?
      e
    end

    def copy_into(target_graph, opts = {})
      iv = target_graph.vertex(in_v.get_id)
      ov = target_graph.vertex(out_v.get_id)
      return if not iv or not ov
      e = target_graph.create_edge nil, iv, ov, label
      properties.each do |name, value|
        e[name] = value
      end
      yield e if block_given?
      e
    end
  end
end
