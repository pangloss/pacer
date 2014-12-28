module Pacer::Core::Graph
  module PathRoute
    def help(section = nil)
      case section
      when :paths
        puts <<HELP
The following path-specific route methods are available:

See also the :arrays section for more available methods

#subgraph(target_graph, opts)   Add each element in the path to the graph
    target_graph: PacerGraph (optional) if not specified creates a new TG.
    opts:
      create_vertices: Boolean          Create vertices for edges if needed
          Edges can not be created without both vertices being present. If
          this option is not set and a vertex is missing, raises a
          Pacer::ElementNotFound exception.
      ignore_missing_vertices: Boolean  Squelches the above mentioned exception
      show_missing_vertices: Boolean    Complain about missing vertices

#hashify            Make a hash of the properties and relationships of the path
    This is just a simple view on the data to facilitate analysis

HELP
      else
        super
      end
      description
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

    def payloads
      map element_type: :path, route_name: 'payloads' do |path|
        path.flat_map do |e|
          e = e.element if e.is_a? Pacer::Wrappers::ElementWrapper
          r = []
          while e.is_a? Pacer::Payload::Element
            r.unshift e.payload
            e = e.element
          end
          if r == []
            [nil]
          else
            r
          end
        end
      end
    end

    def transpose
      map(element_type: :array, &:to_a).transpose
    end

    def heads(et = :vertex)
      super et
    end

    def tails(et = :vertex)
      super et
    end

    def hashify
      map(element_type: :hash, route_name: 'trees') do |path|
        path.to_a.reverse.reduce({}) do |tree, element|
          if element.element_type == :vertex
            tree.merge element.properties
          else
            { element.label => [tree] }
          end
        end
      end
    end
    protected

    def configure_iterator(iter = nil, g = nil)
      if respond_to? :graph
        pipe = Pacer::Pipes::PathWrappingPipe.new(g || graph)
        pipe.setStarts iter
        pipe
      else
        iter
      end
    end
  end
end
