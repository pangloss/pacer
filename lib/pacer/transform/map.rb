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

  mapped = [1,2,3].to_route.map { |n| n + 1 }   #=> #<Obj -> Obj-Map>

  mapped.to_a                                   #=> [2,3,4]
  mapped.limit(1).to_a                          #=> [2]

Note that the block will be called *twice* in the above example where limit(1)
is applied to the route after the map is defined. Routes do some pre-processing
and you can not assume that a function executed within a route will be executed
the expected number of times without carefully testing your logic.

Further, note that routes may be re-executed multiple times:

  [mapped.to_a, mapped.to_a]                    #=> [[2,3,4], [2,3,4]]

The element_type option is frequently useful. The following looks up elements
by ID in the graph and produces a fully-fledged vertices route:

  route = [1,2,3].to_route
  mapped = route.map(graph: g, element_type: :vertex) { |n| g.vertex(n) }

  mapped.out_e                                  #=> #<Obj -> V-Map -> outE>
  mapped.in_e                                   #=> #<Obj -> V-Map -> inE>

If you want to map over a route immediately without adding a map step to it,
use the synonym for #map built-in to Ruby: #collect

  [1,2,3].to_route.collect { |n| n + 1 }        #=> [2,3,4]

HELP
        else
          super
        end
        description
      end

      protected

      def attach_pipe(end_pipe)
        # Must wrap based on parent pipe because the element in the block has
        # not yet been affected by any of this block's transforms.
        if back and back.element_type == :path
          pf = Pacer::Wrappers::PathWrappingPipeFunction.new back, block
        else
          pf = Pacer::Wrappers::WrappingPipeFunction.new back || pacer_source, block
          pf = Pacer::Wrappers::UnwrappingPipeFunction.new pf
        end
        pipe = com.tinkerpop.pipes.transform.TransformFunctionPipe.new pf
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
