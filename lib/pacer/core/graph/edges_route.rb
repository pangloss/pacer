module Pacer::Core::Graph

  # Basic methods for routes that contain only edges.
  module EdgesRoute
    include ElementRoute

    # Extends the route with out vertices from this route's matching edges.
    def out_v(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => Pacer::Pipes::EdgeVertexPipe,
                                               :pipe_args => Pacer::Pipes::EdgeVertexPipe::Step::OUT_VERTEX,
                                               :route_name => 'outV'),
                                  filters, block)
    end

    # Extends the route with in vertices from this route's matching edges.
    def in_v(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => Pacer::Pipes::EdgeVertexPipe,
                                               :pipe_args => Pacer::Pipes::EdgeVertexPipe::Step::IN_VERTEX,
                                               :route_name => 'inV'),
                                  filters, block)
    end

    # Extends the route with both in and oud vertices from this route's matching edges.
    def both_v(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => Pacer::Pipes::EdgeVertexPipe,
                                               :pipe_args => Pacer::Pipes::EdgeVertexPipe::Step::BOTH_VERTICES,
                                               :route_name => 'bothV'),
                                  filters, block)
    end

    # Extend route with the additional edge label, property and block filters.
    def e(*filters, &block)
      filter(*filters, &block)
    end

    # Return an iterator of or yield all labels
    def labels
      chain_route(:pipe_class => com.tinkerpop.pipes.pgm.LabelPipe, :route_name => 'labels')
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

    protected

    def id_pipe_class
      com.tinkerpop.pipes.pgm.IdEdgePipe
    end
  end
end
