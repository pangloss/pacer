module Pacer
  module Routes
    # TODO: this should only apply to ID routes...do we want to be that granular with route types?
    module RouteOperations
      # args is (optional) extensions followed by an (optional) options hash
      def lookup_ids(*args)
        if args.last.is_a? Hash
          opts = args.pop
        else
          opts = {}
        end
        chain_route({transform: :lookup_ids, element_type: :vertex, extensions: args, wrapper: nil}.merge(opts))
      end
    end
  end

  module Transform
    module LookupIds
      import com.tinkerpop.gremlin.pipes.transform.IdVertexPipe
      import com.tinkerpop.gremlin.pipes.transform.IdEdgePipe

      def attach_pipe(end_pipe)
        fail ClientError, 'Can not look up elements without the graph' unless graph
        if element_type == :vertex
          pipe = IdVertexPipe.new graph.blueprints_graph
        elsif element_type == :vertex
          pipe = IdEdgePipe.new graph.blueprints_graph
        else
          fail ClientError, 'Can not look up elements without the element_type'
        end
        pipe.setStarts end_pipe
        pipe
      end
    end
  end
end
