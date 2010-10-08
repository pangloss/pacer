module Pacer::Routes
  module EdgesRouteModule
    # Extends the route with out vertices from this route's matching edges.
    def out_v(*filters, &block)
      VerticesRoute.new(self, filters, block, Pacer::Pipes::EdgeVertexPipe::Step::OUT_VERTEX)
    end

    # Extends the route with in vertices from this route's matching edges.
    def in_v(*filters, &block)
      VerticesRoute.new(self, filters, block, Pacer::Pipes::EdgeVertexPipe::Step::IN_VERTEX)
    end

    # Extends the route with both in and oud vertices from this route's matching edges.
    def both_v(*filters, &block)
      VerticesRoute.new(self, filters, block, Pacer::Pipes::EdgeVertexPipe::Step::BOTH_VERTICES)
    end

    # v is undefined for edge routes.
    def v(*filters)
      raise "Can't call vertices for EdgesRoute."
    end

    # Return a new route with the additional label, property and block filters given.
    def e(*filters, &block)
      path = EdgesRoute.new(self, filters, block)
      path.pipe_class = nil
      path
    end

    # Return an iterator of or yield all labels
    def labels
      if block_given?
        each do |e|
          yield e.get_label
        end
      else
        enum = to_enum(:each)
        enum.extend IteratorBlockMixin
        enum.block = proc { |e| e.get_label }
        enum
      end
    end

    # Stores the result of the current path in a new path so it will not need
    # to be recalculated.
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

    # Returns a hash of in vertices with an array of associated out vertices.
    #
    # See #subgraph for a more useful method.
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
        label_pipe = Pacer::Pipes::LabelsFilterPipe.new
        label_pipe.set_labels labels
        label_pipe.set_starts pipe
        super(label_pipe, filters - labels, block)
      end
    end
  end
end
