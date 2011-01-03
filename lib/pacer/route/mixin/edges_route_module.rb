module Pacer::Routes

  # Basic methods for routes that contain only edges.
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
      raise Pacer::UnsupportedOperation, "Can't call vertices for EdgesRoute."
    end

    # Extend route with the additional edge label, property and block filters.
    def e(*filters, &block)
      route = EdgesRoute.new(self, filters, block)
      route.pipe_class = nil
      route.add_extensions extensions unless route.extensions.any?
      route
    end

    def filter(*args, &block)
      e(*args, &block)
    end

    # Return an iterator of or yield all labels
    def labels
      map { |e| e.get_label }
    end

    # Stores the result of the current route in a new route so it will not need
    # to be recalculated.
    def result(name = nil)
      edge_ids = ids
      if edge_ids.count == 1
        e = graph.edge ids.first
        e.add_extensions extensions
        e
      else
        r = EdgesRoute.from_edge_ids graph, edge_ids
        r.info = "#{ name }:#{r.info}" if name
        r.add_extensions extensions
        r.graph = graph
        r
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

    # Specialize filter_pipe for edge labels.
    def filter_pipe(pipe, filters, block, expand_extensions)
      pipe, filters = expand_extension_conditions(pipe, filters) if expand_extensions
      labels = filters.select { |arg| arg.is_a? Symbol or arg.is_a? String }
      if labels.empty?
        super
      else
        label_pipe = Pacer::Pipes::LabelsFilterPipe.new
        label_pipe.set_labels labels
        label_pipe.set_starts pipe
        super(label_pipe, filters - labels, block, false)
      end
    end
  end
end
