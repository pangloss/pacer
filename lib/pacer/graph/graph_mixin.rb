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

    attr_accessor :in_bulk_job

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

    def create_vertex(*args)
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

    def create_edge(id, from_v, to_v, label, props = nil)
      e = addEdge(id, from_v, to_v, label)
      e.graph = self
      if props
        props.each { |k, v| e[k.to_s] = v if v }
      end
      e
    end

    def import(path)
      path = File.expand_path path
      begin
        stream = java.net.URL.new(path).open_stream
      rescue java.net.MalformedURLException
        stream = java.io.FileInputStream.new path
      end
      com.tinkerpop.blueprints.pgm.parser.GraphMLReader.input_graph self, stream
      true
    end

    def export(path)
      path = File.expand_path path
      stream = java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.pgm.parser.GraphMLWriter.outputGraph self, stream
    end

    def bulk_job_size=(size)
      @bulk_job_size = size
    end

    def bulk_job_size
      @bulk_job_size || 5000
    end

    def in_bulk_job?
      @in_bulk_job
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

  end
end
