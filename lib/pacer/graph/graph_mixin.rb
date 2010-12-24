module Pacer
  module GraphMixin
    def self.included(target)
      target.class_eval do
        protected :addVertex, :addEdge, :add_vertex, :add_edge
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
        sanitize_properties(props).each { |k, v| e[k.to_s] = v }
      end
      v.graph = self
      v
    end

    def create_edge(id, from_v, to_v, label, props = nil)
      e = addEdge(id, from_v.element, to_v.element, label)
      e.graph = self
      if props
        sanitize_properties(props).each { |k, v| e[k.to_s] = v }
      end
      e
    end

    def sanitize_properties(props)
      props.inject({}) do |result, (name, value)|
        case value
        when Symbol
          value = value.to_s
        when ''
          value = nil
        when String
          value = value.strip
          value = nil if value == ''
        else
          value = value.to_s
        end
        result[name] = value if value
        result
      end
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

    def index_name(name, type = nil)
      if type
        indices.detect { |i| i.index_name == name and i.index_type == element_type(type) }
      else
        indices.detect { |i| i.index_name == name }
      end
    end

    def rebuild_automatic_index(old_index)
      name = old_index.index_name
      index_class = old_index.index_class
      keys = old_index.auto_index_keys
      index = create_index name, index_class.java_object, Pacer.automatic_index
      keys.each { |key| index.add_auto_index_key key }
      if index_class == element_type(:vertex).java_class
        v.bulk_job { |v| index.add_element v }
      else
        e.bulk_job { |e| index.add_element e }
      end
    end
  end
end
