module Pacer::Routes
  module VerticesRouteModule
    def out_e(*filters, &block)
      EdgesRoute.new(self, filters, block, Pacer::Pipes::VertexEdgePipe::Step::OUT_EDGES)
    end

    def in_e(*filters, &block)
      EdgesRoute.new(self, filters, block, Pacer::Pipes::VertexEdgePipe::Step::IN_EDGES)
    end

    def both_e(*filters, &block)
      EdgesRoute.new(self, filters, block, Pacer::Pipes::VertexEdgePipe::Step::BOTH_EDGES)
    end

    def v(*filters, &block)
      path = VerticesRoute.new(self, filters, block)
      path.pipe_class = nil
      path
    end

    def e(*filters, &block)
      raise "Can't call edges for VerticesRoute."
    end

    def result(name = nil)
      v_ids = ids
      if v_ids.count > 1
        g = graph
        r = VerticesRoute.new(proc { graph.load_vertices(v_ids) })
        r.info = "#{ name }:#{v_ids.count}"
        r.graph = g
        r.pipe_class = nil
        r
      else
        graph.vertex v_ids.first
      end
    end

    def to(label, to_vertices, props = {})
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
        to_vertices.map do |to_v|
          begin
            e = graph.add_edge(nil, from_v, to_v, label)
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
