module Pacer
  module GraphRoute
    def v(*filters, &block)
      path = VerticesRoute.new(proc { self.get_vertices }, filters, block)
      path.pipe_class = nil
      path.graph = self
      path
    end

    def e(*filters, &block)
      path = EdgesRoute.new(proc { self.get_edges }, filters, block)
      path.pipe_class = nil
      path.graph = self
      path
    end

    def [](id)
      vertex id
    end

    def result
      self
    end

    def root?
      true
    end

    def vertex_name
      @vertex_name
    end

    def vertex_name=(a_proc)
      @vertex_name = a_proc
    end

    def columns
      @columns || 120
    end

    def columns=(n)
      @columns = n
    end

    def inspect_limit
      @inspect_limit || 500
    end

    def inspect_limit=(n)
      @inspect_limit = n
    end

    def load_vertices(ids)
      ids.map do |id|
        vertex id rescue nil
      end.compact
    end

    def load_edges(ids)
      ids.map do |id|
        edge id rescue nil
      end.compact
    end

    protected

    def inspect_route
      true
    end
  end
end
