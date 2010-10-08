module Pacer::Routes

  # Basic methods for routes that may contain both vertices and edges. That can
  # happen as the result of a branched route, for example.
  module MixedRouteModule

    # Pass through only vertices.
    def v
      VerticesRoute.pipe_filter(self, Pacer::Pipes::TypeFilterPipe, Pacer::VertexMixin)
    end

    # Pass through only edges.
    def e
      EdgesRoute.pipe_filter(self, Pacer::Pipes::TypeFilterPipe, Pacer::EdgeMixin)
    end

    # Out edges from matching vertices.
    def out_e(*args, &block)
      v.out_e(*args, &block)
    end

    # In edges from matching vertices.
    def in_e(*args, &block)
      v.in_e(*args, &block)
    end

    # All edges from matching vertices.
    def both_e(*args, &block)
      v.both_e(*args, &block)
    end

    # Out vertices from matching edges.
    def out_v(*args, &block)
      e.out_v(*args, &block)
    end

    # In vertices from matching edges.
    def in_v(*args, &block)
      e.in_v(*args, &block)
    end

    # All vertices from matching edges.
    def both_v(*args, &block)
      e.both_v(*args, &block)
    end

    # Return an iterator of or yield all labels on matching edges.
    def labels(&block)
      e.labels(&block)
    end

    # Calculate and save result.
    def result(name = nil)
      ids = map do |element|
        if element.is_a? Pacer::VertexMixin
          [:vertex, element.id]
        else
          [:edge, element.id]
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
