module Pacer::Core::Graph

  # Basic methods for routes that contain only vertices.
  module VerticesRoute

    # Extends the route with out edges from this route's matching vertices.
    def out_e(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => Pacer::Pipes::VertexEdgePipe,
                                               :pipe_args => Pacer::Pipes::VertexEdgePipe::Step::OUT_EDGES),
                                  filters, block)
    end

    # Extends the route with in edges from this route's matching vertices.
    def in_e(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => Pacer::Pipes::VertexEdgePipe,
                                               :pipe_args => Pacer::Pipes::VertexEdgePipe::Step::IN_EDGES),
                                  filters, block)
    end

    # Extends the route with all edges from this route's matching vertices.
    def both_e(*filters, &block)
      Pacer::Route.property_filter(chain_route(:element_type => :edge,
                                               :pipe_class => Pacer::Pipes::VertexEdgePipe,
                                               :pipe_args => Pacer::Pipes::VertexEdgePipe::Step::BOTH_EDGES),
                                  filters, block)
    end

    # Extend route with the additional vertex property and block filters.
    def v(*filters, &block)
      Pacer::Route.property_filter(self, filters, block)
    end

    def filter(*args, &block)
      v(*args, &block)
    end

    def element_type
      graph.element_type(:vertex)
    end

    # Undefined for vertex routes.
    def e(*filters, &block)
      raise Pacer::UnsupportedOperation, "Can't call edges for VerticesRoute."
    end

    # Delete all matching elements.
    def delete!
      uniq.both_e.uniq.bulk_job { |e| e.delete! }
      uniq.bulk_job { |e| e.delete! }
    end

    # Stores the result of the current route in a new route so it will not need
    # to be recalculated.
    def result(name = nil)
      v_ids = element_ids.to_a
      if v_ids.count == 1
        v = graph.vertex v_ids.first
        v.add_extensions extensions
        v
      else
        r = self.class.from_vertex_ids graph, v_ids
        r.info = "#{ name }:#{r.info}" if name
        r.add_extensions extensions
        r.graph = graph
        r
      end
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
      unless graph
        v = (detect { |v| v.graph } || to_vertices.detect { |v| v.graph })
        graph = v.graph if v
        unless graph
          Pacer.debug_info << { :error => 'No graph found', :from => self, :to => to_vertices, :graph => graph }
          raise "No graph found"
        end
      end
      has_props = !props.empty?
      first_edge_id = last_edge_id = nil
      counter = 0
      graph.managed_transactions do
        graph.managed_transaction do
          each do |from_v|
            to_vertices.to_route.each do |to_v|
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
  end
end
