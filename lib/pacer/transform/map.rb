module Pacer
  module Routes
    module RouteOperations
      def map(opts = {}, &block)
        chain_route({:transform => :map, :block => block, :element_type => :object, :extensions => []}.merge(opts))
      end
    end
  end

  module Transform
    module Map
      attr_accessor :block

      def help(section = nil)
        case section
        when nil
          puts <<HELP
Works much like Ruby's built-in map method but has some extra options and,
like all routes, does not evaluate immediately (see the :routes help topic).

Example:

  mapped = [1, 2, 3].to_route.map { |n| n + 1 } #=> #<Obj -> Obj-Map>

  mapped.to_a          #=> [2, 3, 4]
  mapped.limit(2).to_a #=> [2, 3] - Note that the block will only be called twice.

The element_type option is frequently useful. The following looks up elements
by ID in the graph and produces a fully-fledged vertices route:

  route = [1, 2, 3].to_route
  mapped = route.map(graph: g, element_type: :vertex) { |n| g.vertex(n) }

  mapped.out_e                  #=> #<Obj -> V-Map -> outE>
  mapped.in_e                   #=> #<Obj -> V-Map -> inE>

HELP
        else
          super
        end
      end

      protected

      def attach_pipe(end_pipe)
        # Must wrap based on parent pipe because the element in the block has
        # not yet been affected by any of this block's transforms.
        if back.element_type == :path
          pf = Pacer::Wrappers::PathWrappingPipeFunction.new back || source, block
        else
          pf = Pacer::Wrappers::WrappingPipeFunction.new back || source, block
          pf = Pacer::Wrappers::UnwrappingPipeFunction.new pf
        end
        pipe = com.tinkerpop.pipes.transform.TransformFunctionPipe.new pf
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
