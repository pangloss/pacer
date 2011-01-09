module Pacer::Routes

  # This module adds route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphRoute
    include BranchableRoute

    # Returns a new route to all graph vertices. Standard filter options.
    def v(*filters, &block)
      route = indexed_route(:vertex, filters, block)
      unless route
        route = VerticesRoute.new(self)
        route.pipe_class = Pacer::Pipes::GraphElementPipe
        route.set_pipe_args Pacer::Pipes::GraphElementPipe::ElementType::VERTEX
        route.graph = self
        route = FilterRoute.property_filter(route, filters, block)
      end
      route
    end

    # Returns a new route to all graph edges. Standard filter options.
    def e(*filters, &block)
      route = indexed_route(:edge, filters, block)
      unless route
        route = EdgesRoute.new(self, filters, block)
        route.pipe_class = Pacer::Pipes::GraphElementPipe
        route.set_pipe_args Pacer::Pipes::GraphElementPipe::ElementType::EDGE
        route.graph = self
        route = FilterRoute.property_filter(route, filters, block)
      end
      route
    end

    def filter(*args)
      raise 'Not implemented'
    end

    # Specialization of result simply returns self.
    def result
      self
    end

    # The graph itself is as root as you can get.
    def root?
      true
    end

    def graph
      # This must be defined here to overwrite the #graph method in Base.
      self
    end

    def ==(other)
      equal?(other)
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
        elsif filter.is_a? Module or filter.is_a? Class
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
          keys = index.auto_index_keys_in_use
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
        if index_value.is_a? Module or index_value.is_a? Class
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
