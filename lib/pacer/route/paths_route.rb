module Pacer::Routes
  class PathsRoute
    include Base

    def initialize(back)
      @back = back
    end

    alias each each_path

    def root?
      false
    end

    def transpose
      to_a.transpose
    end

    def subgraph(target_graph = nil)
      raise "Can't create a subgraph within itself." if target_graph == graph
      target_graph ||= Pacer.tg
      target_graph.vertex_name ||= graph.vertex_name
      each do |path|
        path.select { |e| e.is_a? Pacer::VertexMixin }.each do |vertex|
          next if target_graph.vertex(vertex.id)
          v = target_graph.add_vertex vertex.id
          vertex.properties.each do |name, value|
            v[name] = value
          end
        end

        path.select { |e| e.is_a? Pacer::EdgeMixin }.each do |edge|
          next if target_graph.edge(edge.id)
          e = target_graph.add_edge edge.id, target_graph.vertex(edge.out_v.id), target_graph.vertex(edge.in_v.id), edge.label
          edge.properties.each do |name, value|
            e[name] = value
          end
        end
      end
      target_graph
    end

    protected

    def has_routable_class?
      false
    end
  end
end
