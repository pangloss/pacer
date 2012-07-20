module Pacer::Core::Graph

  # This module adds indexed route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphIndexRoute
    # Returns a new route to all graph vertices. Standard filter options.
    def v(*filters, &block)
      filters = Pacer::Route.filters(filters)
      route = indexed_route(:vertex, filters, block)
      if route
        route
      else
        super(filters, &block)
      end
    end

    # Returns a new route to all graph edges. Standard filter options.
    def e(*filters, &block)
      filters = Pacer::Route.edge_filters(filters)
      route = indexed_route(:edge, filters, block)
      if route
        route
      else
        super(filters, &block)
      end
    end

    attr_accessor :choose_best_index
    attr_accessor :search_manual_indices

    private

    def indexed_route(element_type, filters, block)
      filters.graph = self
      filters.indices = graph.getIndices
      filters.choose_best_index = choose_best_index != false
      filters.search_manual_indices = @search_manual_indices
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
