module Pacer
  module EdgesRouteModule
    def out_v(*filters, &block)
      VerticesRoute.new(self, filters, block, EdgeVertexPipe::Step::OUT_VERTEX)
    end

    def in_v(*filters, &block)
      VerticesRoute.new(self, filters, block, EdgeVertexPipe::Step::IN_VERTEX)
    end

    def both_v(*filters, &block)
      VerticesRoute.new(self, filters, block, EdgeVertexPipe::Step::BOTH_VERTICES)
    end

    def v(*filters)
      raise "Can't call vertices for EdgesRoute."
    end

    def e(*filters, &block)
      path = EdgesRoute.new(self, filters, block)
      path.pipe_class = nil
      path
    end

    def labels
      map { |e| e.get_label }
    end

    def result(name = nil)
      edge_ids = ids
      if edge_ids.count > 1
        g = graph
        r = EdgesRoute.new(proc { graph.load_edges(edge_ids) })
        r.graph = g
        r.pipe_class = nil
        r.info = "#{ name }:#{edge_ids.count}"
        r
      else
        graph.edge ids.first
      end
    end

    def to_h
      inject(Hash.new { |h,k| h[k]=[] }) do |h, edge|
        h[edge.out_vertex] << edge.in_vertex
        h
      end
    end

    protected

    # The filters and block this processes are the ones that are passed to the
    # initialize method, not the ones passed to in_v, out_v, etc...
    def filter_pipe(pipe, filters, block)
      labels = filters.select { |arg| arg.is_a? Symbol or arg.is_a? String }
      if labels.empty?
        super
      else
        label_pipe = LabelsFilterPipe.new
        label_pipe.set_labels labels
        label_pipe.set_starts pipe
        super(label_pipe, filters - labels, block)
      end
    end
  end
end
