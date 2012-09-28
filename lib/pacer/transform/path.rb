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

      protected

      def attach_pipe(end_pipe)
        pipe = PathPipe.new
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def configure_iterator(iter)
        if respond_to? :graph
          pipe = Pacer::Pipes::PathWrappingPipe.new(graph)
          pipe.setStarts iter
          pipe
        else
          iter
        end
      end
    end
  end
end
