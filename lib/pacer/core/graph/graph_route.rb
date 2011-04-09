module Pacer::Core::Graph

  # This module adds route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphRoute
    # Returns a new route to all graph vertices. Standard filter options.
    def v(*filters, &block)
      filters = Pacer::Route.filters(filters)
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
      filters = Pacer::Route.edge_filters(filters)
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

    def indexed_route(element_type, filters, block)
      filters.graph = self
      filters.indices = graph.indices
      filters.choose_best_index = true
      idx, key, value = filters.best_index(element_type)
      if idx and key
        route = chain_route :back => self, :element_type => element_type, :filter => :index, :index => idx, :key => key, :value => value
        Pacer::Route.property_filter(route, filters, block)
      elsif filters.route_modules.any?
        mod = filters.route_modules.shift
        Pacer::Route.property_filter(mod.route(self), filters, block)
      end
    end
  end
end
