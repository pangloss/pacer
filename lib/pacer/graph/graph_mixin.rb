module Pacer
  module GraphMixin
    def self.included(target)
      target.class_eval do
        protected :addVertex, :addEdge, :add_vertex, :add_edge
        protected :getVertex, :getEdge, :get_vertex, :get_edge
      end
    end

    attr_accessor :in_bulk_job

    def vertex(id, *modules)
      v = getVertex(id) rescue nil
      if v
        v.graph = self
        v.add_extensions modules
      else
        v
      end
    end

    def edge(id, *modules)
      v = getEdge(id) rescue nil
      if v
        v.graph = self
        v.add_extensions modules
      end
    end

    def find_or_create_vertex(id, *args)
    end

    def create_vertex(*args)
      id, modules, props = id_modules_properties(args)
      vertex = creating_elements { addVertex(id) }
      vertex.graph = self
      sanitize_properties(props).each { |k, v| vertex[k.to_s] = v } if props
      if modules.any?
        vertex.add_extensions modules
      else
        vertex
      end
    end

    def create_edge(id, from_v, to_v, label, *args)
      _, modules, props = id_modules_properties(args)
      edge = creating_elements { addEdge(id, from_v.element, to_v.element, label) }
      edge.graph = self
      sanitize_properties(props).each { |k, v| edge[k.to_s] = v } if props
      if modules.any?
        edge.add_extensions modules
      else
        edge
      end
    end

    def import(path)
      path = File.expand_path path
      begin
        stream = java.net.URL.new(path).open_stream
      rescue java.net.MalformedURLException
        stream = java.io.FileInputStream.new path
      end
      creating_elements do
        com.tinkerpop.blueprints.pgm.util.graphml.GraphMLReader.input_graph self, stream
      end
      true
    ensure
      stream.close if stream
    end

    def export(path)
      path = File.expand_path path
      stream = java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.pgm.util.graphml.GraphMLWriter.outputGraph self, stream
    ensure
      stream.close if stream
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
        vertex id
      end.compact
    end

    def load_edges(ids)
      ids.map do |id|
        edge id
      end.compact
    end

    def index_name(name, type = nil)
      if type
        indices.detect { |i| i.index_name == name and i.index_class == element_type(type) }
      else
        indices.detect { |i| i.index_name == name }
      end
    end

    def rebuild_automatic_index(old_index)
      name = old_index.index_name
      index_class = old_index.index_class
      keys = old_index.auto_index_keys
      drop_index name
      index = create_index name, index_class, Pacer.automatic_index
      keys.each { |key| index.add_auto_index_key key } if keys
      if index_class == element_type(:vertex).java_class
        v.bulk_job do |v|
          Pacer::Utils::IndexHelper.autoIndexElement(index, v)
        end
      else
        e.bulk_job do |e|
          Pacer::Utils::IndexHelper.autoIndexElement(index, e)
        end
      end
      index
    end

    def graph
      self
    end

    # The proc used to name vertices.
    def vertex_name
      @vertex_name
    end

    # Set the proc used to name vertices.
    def vertex_name=(a_proc)
      @vertex_name = a_proc
    end

    # The proc used to name edges.
    def edge_name
      @edge_name
    end

    # Set the proc used to name edges.
    def edge_name=(a_proc)
      @edge_name = a_proc
    end

    def index_class(et)
      element_type(et).java_class.to_java
    end

    protected

    def creating_elements
      begin
        yield
      rescue NativeException => e
        if e.message =~ /already exists/
          raise ElementExists, e.message
        else
          raise
        end
      end
    end

    def id_modules_properties(args)
      props = args.last if args.last.is_a? Hash
      modules = args.select { |obj| obj.is_a? Module or obj.is_a? Class }
      id = args.first
      id = nil if id == props or modules.include? id
      [id, modules, props]
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

  end
end
