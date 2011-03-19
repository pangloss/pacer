module Pacer::Core::Graph

  # Basic methods for routes that contain only vertices.
  module VerticesRoute
    include ElementRoute

    # Extends the route with out edges from this route's matching vertices.
    def out_e(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => Pacer::Pipes::VertexEdgePipe,
                                               :pipe_args => Pacer::Pipes::VertexEdgePipe::Step::OUT_EDGES,
                                               :route_name => 'outE'),
                                  filters, block)
    end

    # Extends the route with in edges from this route's matching vertices.
    def in_e(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => Pacer::Pipes::VertexEdgePipe,
                                               :pipe_args => Pacer::Pipes::VertexEdgePipe::Step::IN_EDGES,
                                               :route_name => 'inE'),
                                  filters, block)
    end

    # Extends the route with all edges from this route's matching vertices.
    def both_e(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => Pacer::Pipes::VertexEdgePipe,
                                               :pipe_args => Pacer::Pipes::VertexEdgePipe::Step::BOTH_EDGES,
                                               :route_name => 'bothE'),
                                  filters, block)
    end

    # Extend route with the additional vertex property and block filters.
    def v(*filters, &block)
      filter(*filters, &block)
    end

    def element_type
      graph.element_type(:vertex)
    end

    # Delete all matching elements.
    def delete!
      uniq.both_e.uniq.bulk_job { |e| e.delete! }
      uniq.bulk_job { |e| e.delete! }
    end

    # Create associations with the given label from all vertices
    # matching this route to all vertices matching the given
    # to_route. If any properties are given, they will be applied
    # to each created edge.
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
        if last_edge_id != first_edge_id
          (first_edge_id..last_edge_id)
        else
          first_edge_id
        end
      end
    end

    protected

    def id_pipe_class
      com.tinkerpop.pipes.pgm.IdVertexPipe
    end
  end
end
