module Pacer::Core::Graph

  # This module adds route methods to the basic graph classes returned from the
  # blueprints library.
  module GraphRoute
    import com.tinkerpop.pipes.transform.GraphQueryPipe

    # Returns a new route to all graph vertices. Standard filter options.
    def v(*filters, &block)
      filters = Pacer::Route.filters(self, filters)
      route = chain_route :element_type => :vertex,
        # TODO - change to GraphQueryPipe
        :pipe_class => GraphQueryPipe,
        :pipe_args => [Pacer::Vertex.java_class],
        :route_name => 'GraphV'
      Pacer::Route.property_filter(route, filters, block)
    end

    # Returns a new route to all graph edges. Standard filter options.
    def e(*filters, &block)
      filters = Pacer::Route.edge_filters(self, filters)
      route = chain_route :element_type => :edge,
        :pipe_class => GraphQueryPipe,
        :pipe_args => [Pacer::Edge.java_class],
        :route_name => 'GraphE'
      Pacer::Route.property_filter(route, filters, block)
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
  end
end
