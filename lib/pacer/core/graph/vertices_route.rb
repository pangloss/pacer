module Pacer::Core::Graph

  # Basic methods for routes that contain only vertices.
  module VerticesRoute
    import com.tinkerpop.pipes.pgm.OutEdgesPipe
    import com.tinkerpop.pipes.pgm.InEdgesPipe
    import com.tinkerpop.pipes.pgm.BothEdgesPipe

    include ElementRoute

    # Extends the route with out edges from this route's matching vertices.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [EdgeMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [EdgesRoute]
    def out_e(*filters, &block)
      filters = extract_sole_label(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => OutEdgesPipe,
                                               :pipe_args => sole_label,
                                               :route_name => edge_route_name('outE')),
                                  filters, block)
    end

    # Extends the route with in edges from this route's matching vertices.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [EdgeMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [EdgesRoute]
    def in_e(*filters, &block)
      filters = extract_sole_label(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => InEdgesPipe,
                                               :pipe_args => sole_label,
                                               :route_name => edge_route_name('inE')),
                                  filters, block)
    end

    # Extends the route with all edges from this route's matching vertices.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
    # @yield [EdgeMixin(Extensions::BlockFilterElement)] filter proc, see {Pacer::Route#property_filter}
    # @return [EdgesRoute]
    def both_e(*filters, &block)
      filters = extract_sole_label(filters)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => BothEdgesPipe,
                                               :pipe_args => sole_label,
                                               :route_name => edge_route_name('bothE')),
                                  filters, block)
    end

    # Extend route with the additional vertex property and block filters.
    #
    # @param [Array<Hash, extension>, Hash, extension] filter see {Pacer::Route#property_filter}
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

      # NOTE: this originally gave me a lot of problems but I think the issues
      # that caused routes to sometimes not have graphs are fixed. If the error
      # comes back, uncomment the fix below. Hopefully this can be removed
      # soon. (dw 2011-03-19)
      #unless graph
      #  v = (detect { |v| v.graph } || to_vertices.detect { |v| v.graph })
      #  graph = v.graph if v
      #  unless graph
      #    Pacer.debug_info << { :error => 'No graph found', :from => self, :to => to_vertices, :graph => graph }
      #    raise "No graph found"
      #  end
      #end

      has_props = !props.empty?
      first_edge_id = last_edge_id = nil
      counter = 0
      graph.managed_transactions do
        graph.managed_transaction do
          each do |from_v|
            to_vertices.each do |to_v|
              counter += 1
              graph.managed_checkpoint if counter % graph.bulk_job_size == 0
              begin
                edge = graph.create_edge(nil, from_v, to_v, label.to_s, props)
                first_edge_id ||= edge.element_id
                last_edge_id = edge.element_id
              end
            end
          end
        end
      end
      if first_edge_id
        (first_edge_id..last_edge_id).id_to_element_route(:based_on => graph.e)
      end
    end

    def sole_label
      @sole_label
    end

    protected

    def edge_route_name(prefix)
      if sole_label
        "#{prefix}(#{sole_label.first.to_sym.inspect})"
      else
        prefix
      end
    end

    def extract_sole_label(filters)
      filters = Pacer::Route.edge_filters(filters)
      if filters.labels.count == 1
        @sole_label = filters.labels
        filters.labels = []
      else
        @sole_label = nil
      end
      filters
    end

    # TODO: move id_pipe_class into the element_type object
    def id_pipe_class
      com.tinkerpop.pipes.pgm.IdVertexPipe
    end
  end
end
