module Pacer::Routes

  # Basic methods for routes that contain only vertices.
  module VerticesRouteModule

    # Extends the route with out edges from this route's matching vertices.
    def out_e(*filters, &block)
      EdgesRoute.new(self, filters, block, Pacer::Pipes::VertexEdgePipe::Step::OUT_EDGES)
    end

    # Extends the route with in edges from this route's matching vertices.
    def in_e(*filters, &block)
      EdgesRoute.new(self, filters, block, Pacer::Pipes::VertexEdgePipe::Step::IN_EDGES)
    end

    # Extends the route with all edges from this route's matching vertices.
    def both_e(*filters, &block)
      EdgesRoute.new(self, filters, block, Pacer::Pipes::VertexEdgePipe::Step::BOTH_EDGES)
    end

    # Extend route with the additional vertex property and block filters.
    def v(*filters, &block)
      route = VerticesRoute.new(self, filters, block)
      route.pipe_class = nil
      route
    end

    # Undefined for vertex routes.
    def e(*filters, &block)
      raise "Can't call edges for VerticesRoute."
    end

    # Stores the result of the current route in a new route so it will not need
    # to be recalculated.
    def result(name = nil)
      v_ids = ids
      if v_ids.count == 1
        graph.vertex v_ids.first
      else
        r = VerticesRoute.from_vertex_ids graph, v_ids
        r.info = "#{ name }:#{r.info}" if name
        r
      end
    end

    # Create associations with the given label from all vertices
    # matching this route to all vertices matching the given
    # to_route. If any properties are given, they will be applied
    # to each created edge.
    def add_edges_to(label, to_vertices, props = {})
      case to_vertices
      when Base, Enumerable, java.util.Iterator
      else
        to_vertices = [to_vertices].compact
      end
      g = graph
      has_props = !props.empty?
      first_edge_id = last_edge_id = nil
      map do |from_v|
        g ||= from_v.graph
        to_vertices.to_route.v.bulk_job do |to_v|
          begin
            edge = (g || to_v.graph).add_edge(nil, from_v, to_v, label)
            first_edge_id ||= edge.get_id
            last_edge_id = edge.get_id
            if has_props
              props.each do |name, value|
                edge.set_property name.to_s, value
              end
            end
          rescue => e
            puts e.message
          end
        end
      end
      (first_edge_id..last_edge_id)
    end
  end
end
