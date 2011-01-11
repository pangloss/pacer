module Pacer::Core::Graph

  # Basic methods for routes that contain only edges.
  module EdgesRoute
    # Extends the route with out vertices from this route's matching edges.
    def out_v(*filters, &block)
      Pacer::Route.property_filter(Pacer::Routes::VerticesRoute.new(self, Pacer::Pipes::EdgeVertexPipe::Step::OUT_VERTEX),
                                  filters, block)
    end

    # Extends the route with in vertices from this route's matching edges.
    def in_v(*filters, &block)
      Pacer::Route.property_filter(Pacer::Routes::VerticesRoute.new(self, Pacer::Pipes::EdgeVertexPipe::Step::IN_VERTEX),
                                  filters, block)
    end

    # Extends the route with both in and oud vertices from this route's matching edges.
    def both_v(*filters, &block)
      Pacer::Route.property_filter(Pacer::Routes::VerticesRoute.new(self, Pacer::Pipes::EdgeVertexPipe::Step::BOTH_VERTICES),
                                  filters, block)
    end

    # v is undefined for edge routes.
    def v(*filters)
      raise Pacer::UnsupportedOperation, "Can't call vertices for EdgesRoute."
    end

    # Extend route with the additional edge label, property and block filters.
    def e(*filters, &block)
      Pacer::Route.property_filter(self, filters, block)
    end

    def filter(*args, &block)
      e(*args, &block)
    end

    # Return an iterator of or yield all labels
    def labels
      map { |e| e.get_label }
    end

    # Stores the result of the current route in a new route so it will not need
    # to be recalculated.
    def result(name = nil)
      edge_ids = element_ids.to_a
      if edge_ids.count == 1
        e = graph.edge edge_ids.first
        e.add_extensions extensions
        e
      else
        r = self.class.from_edge_ids graph, edge_ids
        r.info = "#{ name }:#{r.info}" if name
        r.add_extensions extensions
        r.graph = graph
        r
      end
    end

    # Returns a hash of in vertices with an array of associated out vertices.
    #
    # See #subgraph for a more useful method.
    def to_h
      inject(Hash.new { |h,k| h[k]=[] }) do |h, edge|
        h[edge.out_vertex] << edge.in_vertex
        h
      end
    end

    def element_type
      graph.element_type(:edge)
    end
  end
end
