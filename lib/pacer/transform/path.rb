module Pacer
  module Core
    module Route
      def paths(*exts)
        route = chain_route :transform => :path, :element_type => :path
        if exts.any?
          exts = exts.map { |e| Array.wrap(e) if e }
          route.map(modules: Pacer::Transform::Path::Methods) do |path|
            path.zip(exts).map { |element, ext| ext ? element.add_extensions(ext) : element }
          end
        else
          route
        end
      end
    end
  end

  module Transform
    module Path
      import com.tinkerpop.pipes.transform.PathPipe

      def help(section = nil)
        case section
        when nil
          puts <<HELP
Each path returned by this method represents each intermediate value that was
used to calculate the resulting value:

  r = [1,2,3].to_route.map { |n| n*2 }
  p = r.paths                           #=> #<Obj -> Obj-Map -> Path-Path>
  p.to_a                                #=> [[1,1], [2,4], [3,6]]

This is especially useful for graph traversals.

  g.v.out_e.in_v.out_e.in_v.paths.first #=> [#<V[37]>,
                                        #    #<E[41]:37-patcit-38>,
                                        #    #<V[38]>,
                                        #    #<E[40]:38-document-id-39>,
                                        #    #<V[39]>]

See the :paths section for more details and general information about paths.

HELP
        else
          super
        end
        description
      end

      protected

      def attach_pipe(end_pipe)
        pipe = PathPipe.new
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
