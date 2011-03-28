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

    def create_vertex(*args)
      id, modules, props = id_modules_properties(args)
      vertex = creating_elements { addVertex(id) }
      vertex.graph = self
      props.each { |k, v| vertex[k.to_s] = v } if props
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
      props.each { |k, v| edge[k.to_s] = v } if props
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

    def index_name(name, type = nil, opts = {})
      if type
        idx = indices.detect { |i| i.index_name == name and i.index_class == index_class(type) }
        if idx.nil? and opts[:create]
          idx = createManualIndex name, element_type(type)
        end
      else
        idx = indices.detect { |i| i.index_name == name }
      end
      idx.graph = self if idx
      idx
    end

    def rebuild_automatic_index(old_index)
      name = old_index.getIndexName
      index_class = old_index.getIndexClass
      keys = old_index.getAutoIndexKeys
      drop_index name
      build_automatic_index(name, index_class, keys)
    end

    def build_automatic_index(name, et, keys = nil)
      if keys and not keys.is_a? java.util.Set
        set = java.util.HashSet.new
        keys.each { |k| set.add k.to_s }
        keys = set
      end
      index = createAutomaticIndex name.to_s, index_class(et), keys
      if index_class(et) == element_type(:vertex).java_class
        v.bulk_job do |v|
          Pacer::Utils::AutomaticIndexHelper.addElement(index, v)
        end
      else
        e.bulk_job do |e|
          Pacer::Utils::AutomaticIndexHelper.addElement(index, e)
        end
      end
      index
    end

    def graph
      self
    end

    def description
      toString
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

    def element_type?(et)
      if [element_type(:vertex), element_type(:edge), element_type(:mixed)].include?  element_type(et)
        true
      else
        false
      end
    end

    def supports_circular_edges?
      true
    end

    def supports_custom_element_ids?
      true
    end

    def supports_automatic_indices?
      true
    end

    def supports_manual_indices?
      true
    end

    def supports_edge_indices?
      true
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
  end
end
