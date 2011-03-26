module Pacer::Core::Graph

  # This module adds route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphRoute
    # Returns a new route to all graph vertices. Standard filter options.
    def v(*filters, &block)
      route = indexed_route(:vertex, filters, block)
      unless route
        route = chain_route :element_type => :vertex,
          :pipe_class => Pacer::Pipes::GraphElementPipe,
          :pipe_args => Pacer::Pipes::GraphElementPipe::ElementType::VERTEX,
          :route_name => 'GraphV'
        route = Pacer::Route.property_filter(route, filters, block)
      end
      route
    end

    # Returns a new route to all graph edges. Standard filter options.
    def e(*filters, &block)
      route = indexed_route(:edge, filters, block)
      unless route
        route = chain_route :element_type => :edge,
          :pipe_class => Pacer::Pipes::GraphElementPipe,
          :pipe_args => Pacer::Pipes::GraphElementPipe::ElementType::EDGE,
          :route_name => 'GraphE'
        route = Pacer::Route.property_filter(route, filters, block)
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
      # This must be defined here to overwrite the #graph method in Route.
      self
    end

    def ==(other)
      equal?(other)
    end

    # Don't try to inspect the graph data when inspecting.
    def hide_elements
      true
    end

    protected

    def each_property_filter(filters)
      filters.each do |filter|
        case filter
        when Hash
          filter.each { |key, value| yield key, value, nil if key }
        when Array
          each_property_filter(filter) { |k, v, f| yield k, v, f }
        when Module, Class
          if filter.respond_to? :route_conditions
            each_property_filter([filter.route_conditions]) { |k, v, f| yield k, v, (f || filter) }
          elsif filter.respond_to? :route
            yield filter, filter, filter
          end
        when Symbol, String
          yield 'label', filter, nil
        end
      end
      nil
    end

    def use_index?(index, element_type, index_name, index_value)
      if index.index_class == graph.index_class(element_type)
        key, value, index_specified = index_key_value(index_name, index_value)
        if index.index_type == Pacer.automatic_index
          keys = index.getAutoIndexKeys
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
      each_property_filter(filters) do |index_name, index_value, extension|
        if index_value.is_a? Module or index_value.is_a? Class
          route = index_value.route(self)
          route.add_extension extension if extension
          return Pacer::Route.property_filter(route, filters - [index_value], block)
        elsif index_value
          idx = (indices || []).detect { |i| use_index?(i, element_type, index_name.to_s, index_value) }
          if idx
            key, value = index_key_value(index_name, index_value)
            if element_type == self.element_type(:edge)
              route = chain_route :back => self, :element_type => :edge, :filter => :index, :index => idx, :key => key, :value => value
            else
              route = chain_route :back => self, :element_type => :vertex, :filter => :index, :index => idx, :key => key, :value => value
            end
            route = Pacer::Route.property_filter(route, filters_without_key(filters, key, extension), block)
            route.add_extension extension if extension
            return route
          end
        end
      end
    end

    def filters_without_key(filters, key, extension)
      fs = filters.map do |f|
        if f.is_a? Hash
          f = Hash[f.reject { |k, v| k.to_s == key.to_s }]
          f unless f.empty?
        elsif f.is_a? Array
          filters_without_key(f, key, extension)
        elsif f != extension
          f
        end
      end.compact
      fs unless fs.empty?
    end
  end
end
