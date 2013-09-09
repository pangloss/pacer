module Pacer::Core::Graph

  # This module adds indexed route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphIndexRoute
    # If never_scan is true, raise an exception if a graph route does not
    # start with an indexed property. Large databases could spend hours
    # scanning!
    attr_accessor :never_scan
    attr_accessor :choose_best_index
    attr_accessor :search_manual_indices

    # Returns a new route to all graph vertices. Standard filter options.
    def v(*args, &block)
      filters = Pacer::Route.filters(self, args)
      if features.supportsKeyIndices or (search_manual_indices and features.supportsIndices)
        route = indexed_route(:vertex, filters, block)
      end
      if route
        route
      elsif never_scan
        fail Pacer::ClientError, "No indexed properties found among: #{ filters.property_keys.join ', ' }"
      else
        super(filters, &block)
      end
    end

    # Returns a new route to all graph edges. Standard filter options.
    def e(*args, &block)
      filters = Pacer::Route.edge_filters(self, args)
      if features.supportsKeyIndices or (search_manual_indices and features.supportsIndices)
        route = indexed_route(:edge, filters, block)
      end
      if route
        route
      elsif never_scan
        fail Pacer::ClientError, "No indexed properties found among: #{ filters.property_keys.join ', ' }"
      else
        super(filters, &block)
      end
    end

    private

    def indexed_route(element_type, filters, block)
      filters.graph = self
      filters.use_lookup!
      filters.indices = graph.indices
      filters.choose_best_index = choose_best_index != false
      filters.search_manual_indices = search_manual_indices
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
