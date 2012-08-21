module Pacer
  module Core
    module Route
      def paths(*exts)
        route = chain_route :transform => :path, :element_type => :object
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
      module Methods
        def transpose
          collect { |arraylist| arraylist.to_a }.transpose
        end

        def subgraph(target_graph = nil, opts = {})
          raise "Can't create a subgraph within itself." if target_graph == graph
          target_graph ||= Pacer.tg
          target_graph.vertex_name ||= graph.vertex_name
          missing_edges = Set[]
          bulk_job(nil, target_graph) do |path|
            path.select { |e| e.is_a? Pacer::Vertex }.each do |vertex|
              vertex.clone_into target_graph
            end
            path.select { |e| e.is_a? Pacer::Edge }.each do |edge|
              unless edge.clone_into target_graph, ignore_missing_vertices: true
                missing_edges << edge
              end
            end
          end
          if missing_edges.any?
            missing_edges.to_route(graph: graph, element_type: :edge).bulk_job nil, target_graph do |edge|
              edge.clone_into target_graph,
                ignore_missing_vertices: opts[:ignore_missing_vertices],
                show_missing_vertices: opts[:show_missing_vertices]
            end
          end
          target_graph
        end
      end

      import com.tinkerpop.pipes.transform.PathPipe

      include Methods

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
