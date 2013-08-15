module Pacer::Core::Graph

  # Basic methods for routes that may contain both vertices and edges. That can
  # happen as the result of a branched route, for example.
  module MixedRoute
    # Pass through only vertices.
    def v(*args, &block)
      route = chain_route :element_type => :vertex,
        :pipe_class => Pacer::Pipes::TypeFilterPipe,
        :pipe_args => Pacer::Vertex,
        :wrapper => wrapper,
        :extensions => extensions
      Pacer::Route.property_filter(route, args, block)
    end

    # Pass through only edges.
    def e(*args, &block)
      route = chain_route :element_type => :edge,
        :pipe_class => Pacer::Pipes::TypeFilterPipe,
        :pipe_args => Pacer::Edge,
        :wrapper => wrapper,
        :extensions => extensions
      Pacer::Route.property_filter(route, args, block)
    end

    def filter(*args, &block)
      mixed(*args, &block)
    end

    def mixed(*args, &block)
      route = chain_route :pipe_class => Pacer::Pipes::IdentityPipe
      Pacer::Route.property_filter(route, args, block)
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

    def element_type
      :mixed
    end

    # Calculate and save result.
    def result(name = nil)
      ids = collect do |element|
        if element.is_a? Pacer::Vertex
          [:vertex, element.element_id]
        else
          [:edge, element.element_id]
        end
      end
      args = {
        :graph => graph,
        :element_type => :mixed,
        :extensions => extensions,
        :info => [name, info].compact.join(':')
      }
      ids.to_route(:info => "#{ ids.count } ids").map(args) do |method, id|
        graph.send(method, id)
      end
    end
  end
end
