module Pacer::Route
  module MixedRouteModule
    def v
      VerticesRoute.pipe_filter(self, Pacer::Pipe::TypeFilterPipe, Pacer::VertexMixin)
    end

    def e
      EdgesRoute.pipe_filter(self, Pacer::Pipe::TypeFilterPipe, Pacer::EdgeMixin)
    end

    def out_e(*args, &block)
      v.out_e(*args, &block)
    end

    def in_e(*args, &block)
      v.in_e(*args, &block)
    end

    def both_e(*args, &block)
      v.both_e(*args, &block)
    end

    def out_v(*args, &block)
      e.out_v(*args, &block)
    end

    def in_v(*args, &block)
      e.in_v(*args, &block)
    end

    def both_v(*args, &block)
      e.both_v(*args, &block)
    end

    def labels
      e.map { |e| e.get_label }
    end

    def result(name = nil)
      ids = map do |element|
        if element.is_a? Pacer::Vertex
          [:load_vertex, element.id]
        else
          [:load_edge, element.id]
        end
      end
      if ids.count > 1
        g = graph
        loader = proc do
          ids.map { |method, id| graph.send(method, id) }
        end
        r = MixedElementsRoute.new(loader)
        r.graph = g
        r.pipe_class = nil
        r.info = "#{ name }:#{ids.count}"
        r
      else
        method, id = ids.first
        graph.send method, id
      end
    end
  end
end
