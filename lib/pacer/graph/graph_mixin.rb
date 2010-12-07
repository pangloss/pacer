module Pacer
  module GraphMixin
    def self.included(target)
      target.class_eval do
        protected :addVertex, :addEdge
        protected :getVertex, :getEdge
        alias vertex get_vertex
        alias edge get_edge
      end
    end

    def get_vertex(id)
      v = getVertex(id)
      v.graph = self
      v
    end

    def get_edge(id)
      v = getEdge(id)
      v.graph = self
      v
    end

    def add_vertex(*args)
      if args.last.is_a? Hash
        props = args.last
      end
      id = args.first if args.first.is_a? Fixnum
      v = addVertex(id)
      if props
        props.each { |k, v| e[k.to_s] = v if v }
      end
      v.graph = self
      v
    end

    def add_edge(id, from_v, to_v, label, props = nil)
      e = addEdge(id, from_v, to_v, label)
      e.graph = self
      if props
        props.each { |k, v| e[k.to_s] = v if v }
      end
      e
    end

  end
end
