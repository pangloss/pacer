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
          vertex.clone_into target_graph
        end

        path.select { |e| e.is_a? Pacer::EdgeMixin }.each do |edge|
          edge.clone_into target_graph
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
