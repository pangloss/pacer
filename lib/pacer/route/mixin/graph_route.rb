module Pacer::Routes

  # This module adds route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphRoute
    include BranchableRoute

    # Returns a new route to all graph vertices. Standard filter options.
    def v(*filters, &block)
      route = indexed_route(:vertex, filters, block)
      unless route
        route = VerticesRoute.new(proc { self.get_vertices }, filters, block)
        route.pipe_class = nil
        route.graph = self
      end
      route.add_extensions filters
      route
    end

    # Returns a new route to all graph edges. Standard filter options.
    def e(*filters, &block)
      route = indexed_route(:edge, filters, block)
      unless route
        route = EdgesRoute.new(proc { self.get_edges }, filters, block)
        route.pipe_class = nil
        route.graph = self
      end
      route.add_extensions filters
      route
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

    # Index keys are stored here only as they are discovered.
    def index_keys
      @index_keys ||= {}
    end

    protected

    # Don't try to inspect the graph data when inspecting.
    def hide_elements
      true
    end

    def each_property_filter(filters)
      filters.each do |filter|
        if filter.is_a? Hash
          filter.each { |key, value| yield key, value if key }
        elsif filter.is_a? Module
          if filter.respond_to? :route_conditions
            each_property_filter([filter.route_conditions]) { |k, v| yield k, v }
          elsif filter.respond_to? :route
            yield filter, filter
          end
        end
      end
      nil
    end

    def use_index?(index, element_type, index_name, index_value)
      if index.index_class == element_type.java_class
        key, value, index_specified = index_key_value(index_name, index_value)
        if index.index_type == Pacer.automatic_index
          keys = index.auto_index_keys
          return false if keys and not keys.include? key
        end
        index.index_name == index_name or (not index_specified and index.index_type == Pacer.automatic_index)
      end
    end

    def index_key_value(key, value)
      index_specified = value.is_a? Hash
      key, value = value.first if index_specified
      [key.to_s, value, index_specified]
    end

    def indexed_route(element_type, filters, block)
      element_type = self.element_type(element_type)
      each_property_filter(filters) do |index_name, index_value|
        if index_value.is_a? Module
          return index_value.route(self)
        elsif index_value
          idx = (indices || []).detect { |i| use_index?(i, element_type, index_name.to_s, index_value) }
          if idx
            key, value = index_key_value(index_name, index_value)
            if element_type == self.element_type(:edge)
              route = IndexedEdgesRoute.new(idx, key, value, filters, block)
            else
              route = IndexedVerticesRoute.new(idx, key, value, filters, block)
            end
            route.graph = self
            return route
          end
        end
      end
    end
  end
end
