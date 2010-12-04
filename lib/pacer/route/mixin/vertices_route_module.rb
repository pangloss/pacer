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
      when Base
        raise "Must be from same graph" unless to_vertices.from_graph?(graph)
      when Enumerable, Iterator
        raise "Must be from same graph" unless to_vertices.first.from_graph?(graph)
      else
        raise "Must be from same graph" unless to_vertices.from_graph?(graph)
        to_vertices = [to_vertices]
      end
      map do |from_v|
        [*to_vertices].compact.map do |to_v|
          begin
            e = from_v.graph.add_edge(nil, from_v, to_v, label)
            props.each do |name, value|
              e.set_property name.to_s, value
            end
          rescue => e
            puts e.message
          end
        end
      end
    end
  end
end
