module Pacer::Core::Graph

  # Basic methods for routes that contain only edges.
  module EdgesRoute
    import com.tinkerpop.pipes.pgm.OutVertexPipe
    import com.tinkerpop.pipes.pgm.InVertexPipe
    import com.tinkerpop.pipes.pgm.BothVerticesPipe

    include ElementRoute

    # Extends the route with out vertices from this route's matching edges.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [VertexMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [VerticesRoute]
    def out_v(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => OutVertexPipe,
                                               :route_name => 'outV'),
                                  filters, block)
    end

    # Extends the route with in vertices from this route's matching edges.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [VertexMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [VerticesRoute]
    def in_v(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => InVertexPipe,
                                               :route_name => 'inV'),
                                  filters, block)
    end

    # Extends the route with both in and oud vertices from this route's matching edges.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [VertexMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [VerticesRoute]
    def both_v(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => BothVerticesPipe,
                                               :route_name => 'bothV'),
                                  filters, block)
    end

    # Extend route with the additional edge label, property and block filters.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [EdgeMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [EdgesRoute]
    def e(*filters, &block)
      filter(*filters, &block)
    end

    # Return an route to all edge labels for edges emitted from this
    # route.
    #
    # @return [Core::Route]
    def labels
      chain_route(:pipe_class => com.tinkerpop.pipes.pgm.LabelPipe,
                  :route_name => 'labels',
                  :element_type => :object)
    end

    # Returns a hash of in vertices with an array of associated out vertices.
    #
    # See #subgraph for a more useful method.
    #
    # @return [Hash]
    def to_h
      inject(Hash.new { |h,k| h[k]=[] }) do |h, edge|
        h[edge.out_vertex] << edge.in_vertex
        h
      end
    end

    # The element type of this route for this graph implementation.
    #
    # @return [element_type(:edge)] The actual type varies based on
    # which graph is in use.
    def element_type
      graph.element_type(:edge)
    end

    protected

    def id_pipe_class
      com.tinkerpop.pipes.pgm.IdEdgePipe
    end
  end
end
