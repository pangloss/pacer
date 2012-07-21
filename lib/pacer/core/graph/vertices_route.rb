module Pacer::Core::Graph

  # Basic methods for routes that contain only vertices.
  module VerticesRoute
    import com.tinkerpop.pipes.transform.OutEdgesPipe
    import com.tinkerpop.pipes.transform.OutPipe
    import com.tinkerpop.pipes.transform.InEdgesPipe
    import com.tinkerpop.pipes.transform.InPipe
    import com.tinkerpop.pipes.transform.BothEdgesPipe
    import com.tinkerpop.pipes.transform.BothPipe

    include ElementRoute

    # Extends the route with out edges from this route's matching vertices.
    #
    # @param [Array<Hash, String, Symbol, extension>, Hash, String, Symbol, extension] filter see {Pacer::Route#property_filter}
    #   If string(s) or symbol(s) are given, they will be treated as edge
    #   labels. Unlike other property filters which all must be matched, an
    #   edge will pass the filter if it matches any of the given labels.
    # @yield [EdgeMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [EdgesRoute]
    def out_e(*filters, &block)
      filters = extract_labels(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => OutEdgesPipe,
                                               :pipe_args => route_labels,
                                               :route_name => edge_route_name('outE')),
                                  filters, block)
    end

    # Extends the route with vertices via the out edges from this route's matching vertices.
    #
    # @param [Array<Hash, String, Symbol, extension>, Hash, String, Symbol, extension] filter see {Pacer::Route#property_filter}
    #   If string(s) or symbol(s) are given, they will be treated as edge
    #   labels. Unlike other property filters which all must be matched, an
    #   edge will pass the filter if it matches any of the given labels.
    # @yield [VertexMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [VerticesRoute]
    def out(*filters, &block)
      filters = extract_labels(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => OutPipe,
                                               :pipe_args => route_labels,
                                               :route_name => edge_route_name('out')),
                                  filters, block)
    end

    # Extends the route with in edges from this route's matching vertices.
    #
    # @param [Array<Hash, String, Symbol, extension>, Hash, String, Symbol, extension] filter see {Pacer::Route#property_filter}
    #   If string(s) or symbol(s) are given, they will be treated as edge
    #   labels. Unlike other property filters which all must be matched, an
    #   edge will pass the filter if it matches any of the given labels.
    # @yield [EdgeMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [EdgesRoute]
    def in_e(*filters, &block)
      filters = extract_labels(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => InEdgesPipe,
                                               :pipe_args => route_labels,
                                               :route_name => edge_route_name('inE')),
                                  filters, block)
    end

    # Extends the route with vertices via the in edges from this route's matching vertices.
    #
    # @param [Array<Hash, String, Symbol, extension>, Hash, String, Symbol, extension] filter see {Pacer::Route#property_filter}
    #   If string(s) or symbol(s) are given, they will be treated as edge
    #   labels. Unlike other property filters which all must be matched, an
    #   edge will pass the filter if it matches any of the given labels.
    # @yield [VertexMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [VerticesRoute]
    def in(*filters, &block)
      filters = extract_labels(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => InPipe,
                                               :pipe_args => route_labels,
                                               :route_name => edge_route_name('in')),
                                  filters, block)
    end

    # Extends the route with all edges from this route's matching vertices.
    #
    # @param [Array<Hash, String, Symbol, extension>, Hash, String, Symbol, extension] filter see {Pacer::Route#property_filter}
    #   If string(s) or symbol(s) are given, they will be treated as edge
    #   labels. Unlike other property filters which all must be matched, an
    #   edge will pass the filter if it matches any of the given labels.
    # @yield [EdgeMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [EdgesRoute]
    def both_e(*filters, &block)
      filters = extract_labels(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => BothEdgesPipe,
                                               :pipe_args => route_labels,
                                               :route_name => edge_route_name('bothE')),
                                  filters, block)
    end

    # Extends the route with vertices via all edges from this route's matching vertices.
    #
    # @param [Array<Hash, String, Symbol, extension>, Hash, String, Symbol, extension] filter see {Pacer::Route#property_filter}
    #   If string(s) or symbol(s) are given, they will be treated as edge
    #   labels. Unlike other property filters which all must be matched, an
    #   edge will pass the filter if it matches any of the given labels.
    # @yield [VertexMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [VerticesRoute]
    def both(*filters, &block)
      filters = extract_labels(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :vertex,
                                               :pipe_class => BothPipe,
                                               :pipe_args => route_labels,
                                               :route_name => edge_route_name('both')),
                                  filters, block)
    end

    # Extend route with the additional vertex property and block filters.
    #
    # @param [Array<Hash, String, Symbol, extension>, Hash, String, Symbol, extension] filter see {Pacer::Route#property_filter}
    #   If string(s) or symbol(s) are given, they will be treated as edge
    #   labels. Unlike other property filters which all must be matched, an
    #   edge will pass the filter if it matches any of the given labels.
    # @yield [VertexMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [VerticesRoute]
    def v(*filters, &block)
      filter(*filters, &block)
    end

    # The element type of this route for this graph implementation.
    #
    # @return [element_type(:vertex)] The actual type varies based on
    # which graph is in use.
    def element_type
      graph.element_type(:vertex)
    end

    # Delete all matching vertices and all edges which link to this
    # vertex.
    def delete!
      uniq.both_e.uniq.bulk_job { |e| e.delete! }
      uniq.bulk_job { |e| e.delete! }
    end

    # Create associations with the given label from all vertices
    # matching this route to all vertices matching the given
    # to_route. If any properties are given, they will be applied
    # to each created edge.
    #
    # If this route emits more than one element and the to_vertices
    # param also emits (or contains) more than one element, the
    # resulting edges will represent a cross-product between the two
    # collections.
    #
    # If a vertex appears in either the this route or in to_vertices,
    # it will be linked once for each time it appears.
    #
    # @param [#to_s] label the label to use for the new edges
    # @param [VerticesRoute, Enumerable, java.util.Iterator] to_vertices
    #   collection of vertices that should have edges connecting them
    #   from the source edges.
    # @param optional [Hash] props properties that should be set for
    #   each created edge
    # @return [EdgesRoute, nil] includes all created edges or nil if no
    #   edges were created
    def add_edges_to(label, to_vertices, props = {})
      case to_vertices
      when Pacer::Core::Route, Enumerable, java.util.Iterator
      else
        to_vertices = [to_vertices].compact
      end
      graph = self.graph

      has_props = !props.empty?
      edge_ids = []
      each do |from_v|
        to_vertices.each do |to_v|
          begin
            edge = graph.create_edge(nil, from_v, to_v, label.to_s, props)
            edge_ids << edge.element_id
          end
        end
      end
      if edge_ids.any?
        edge_ids.id_to_element_route(:based_on => graph.e)
      end
    end

    def route_labels
      @route_labels
    end

    protected

    def edge_route_name(prefix)
      if route_labels.any?
        "#{prefix}(#{route_labels.map { |l| l.to_sym.inspect }.join ', '})"
      else
        prefix
      end
    end

    def extract_labels(filters)
      filters = Pacer::Route.edge_filters(filters)
      @route_labels = filters.labels
      filters.labels = []
      filters
    end

    # TODO: move id_pipe_class into the element_type object
    def id_pipe_class
      com.tinkerpop.pipes.transform.IdVertexPipe
    end
  end
end
