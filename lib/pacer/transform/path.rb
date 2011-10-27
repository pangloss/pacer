module Pacer
  module Core
    module Route
      def paths
        chain_route :transform => :path, :element_type => :object
      end
    end
  end

  module Transform
    module Path
      import com.tinkerpop.pipes.transform.PathPipe

      def transpose
        collect { |arraylist| arraylist.to_a }.transpose
      end

      def subgraph(target_graph = nil)
        raise "Can't create a subgraph within itself." if target_graph == graph
        target_graph ||= Pacer.tg
        target_graph.vertex_name ||= graph.vertex_name
        bulk_job(nil, target_graph) do |path|
          path_route = path.to_route(:graph => graph, :element_type => :mixed)
          path_route.v.each do |vertex|
            vertex.clone_into target_graph
          end
          path_route.e.each do |edge|
            edge.clone_into target_graph
          end
        end
        target_graph
      end

      protected

      def attach_pipe(end_pipe)
        pipe = PathPipe.new
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def configure_iterator(iter)
        iter.extend Pacer::Core::Route::IteratorPathMixin
      end
    end
  end
end
