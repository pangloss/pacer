module Pacer::Routes

  # This module adds route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphRoute

    # Returns a new path to all graph vertices. Standard filter options.
    def v(*filters, &block)
      path = indexed_vertices_path(filters, block)
      unless path
        path = VerticesRoute.new(proc { self.get_vertices }, filters, block)
        path.pipe_class = nil
        path.graph = self
      end
      path
    end

    # Returns a new path to all graph edges. Standard filter options.
    def e(*filters, &block)
      path = EdgesRoute.new(proc { self.get_edges }, filters, block)
      path.pipe_class = nil
      path.graph = self
      path
    end

    # Specialization of result simply returns self.
    def result
      self
    end

    # The graph itself is as root as you can get.
    def root?
      true
    end

    # The proc used to name vertices.
    def vertex_name
      @vertex_name
    end

    # Set the proc used to name vertices.
    def vertex_name=(a_proc)
      @vertex_name = a_proc
    end

    # The proc used to name edges.
    def edge_name
      @edge_name
    end

    # Set the proc used to name edges.
    def edge_name=(a_proc)
      @edge_name = a_proc
    end

    def graph
      self
    end

    # Load vertices by id.
    def load_vertices(ids)
      ids.map do |id|
        vertex id rescue nil
      end.compact
    end

    # Load edges by id.
    def load_edges(ids)
      ids.map do |id|
        edge id rescue nil
      end.compact
    end

    def index_keys
      @index_keys ||= {}
    end

    protected

    # Don't try to inspect the graph data when inspecting.
    def hide_elements
      true
    end

    def each_property_filter(filters)
      hash = filters.last
      if hash.is_a? Hash
        hash.each { |key, value| yield key, value if key }
      end
      nil
    end

    def indexed_vertices_path(filters, block)
      idx = index rescue nil
      if idx
        each_property_filter(filters) do |key, value|
          if value
            indexed = index_keys.key? key
            unless indexed
              indexed = idx.get key, value
              index_keys[key] = true if indexed
            end
            if indexed
              path = IndexedVerticesRoute.new(idx, key, value, filters, block)
              path.graph = self
              return path
            end
          end
        end
      end
    end

  end
end
