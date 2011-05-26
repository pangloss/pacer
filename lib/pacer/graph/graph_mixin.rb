module Pacer
  # Methods to be mixed into Blueprints Graph objects from any
  # implementation.
  #
  # Adds more convenient/rubyish methods and adds support for extensions
  # to some methods where needed.
  
  require 'json'
  
  module GraphMixin
    def self.included(target)
      target.class_eval do
        protected :addVertex, :addEdge, :add_vertex, :add_edge
        protected :getVertex, :getEdge, :get_vertex, :get_edge
      end
    end

    attr_accessor :in_bulk_job

    # Get a vertex by id.
    #
    # @overload vertex(id)
    #   @param [element id] id
    # @overload vertex(id, *modules)
    #   @param [element id] id
    #   @param [Module, Class] *modules extensions to add to the returned
    #     vertex.
    def vertex(id, *modules)
      v = getVertex(id) rescue nil
      if v
        v.graph = self
        v.add_extensions modules
      else
        v
      end
    end

    # Get an edge by id.
    #
    # @overload edge(id)
    #   @param [element id] id
    # @overload edge(id, *modules)
    #   @param [element id] id
    #   @param [Module, Class] *modules extensions to add to the returned
    #     edge.
    def edge(id, *modules)
      v = getEdge(id) rescue nil
      if v
        v.graph = self
        v.add_extensions modules
      end
    end

    # Create a vertex in the graph.
    #
    # @overload create_vertex(*args)
    #   @param [extension, Hash] *args extension (Module/Class) arguments will be
    #     added to the current vertex. A Hash will be
    #     treated as element properties.
    # @overload create_vertex(id, *args)
    #   @param [element id] id the desired element id. Some graphs
    #     ignore this.
    #   @param [extension, Hash] *args extension (Module/Class) arguments will be
    #     added to the current vertex. A Hash will be
    #     treated as element properties.
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

    # Create an edge in the graph.
    #
    # @param [element id] id some graphs allow you to specify your own edge id.
    # @param [Pacer::VertexMixin] from_v the new edge's out_vertex
    # @param [Pacer::VertexMixin] to_v the new edge's in_vertex
    # @param [#to_s] label the edge label
    # @param [extension, Hash] *args extension (Module/Class) arguments will be
    #   added to the returned edge. A Hash will be
    #   treated as element properties.
    #
    # @todo make id param optional
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

    # Import the data in a GraphML file.
    #
    # Will fail if the data already exsts in the current graph.
    #
    # @param [String] path
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

    # Export the graph to GraphML
    #
    # @param [String] path will be replaced if it exists
    def export(path)
      path = File.expand_path path
      stream = java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.pgm.util.graphml.GraphMLWriter.outputGraph self, stream
    ensure
      stream.close if stream
    end
    
    # Import the data from a JSON string.
    #
    # @param [String] json_data
    #
    # Handling JSON::ParserError?
    def from_json(json_data)
      data = JSON.parse(json_data)
      data['vertices'].each_pair do |_id, vertex|
        next if vertex['_type'] != 'vertex'
        vertex.delete '_type'
        # If present, remove the vertex ID and use all other properties as 
        # vertex properties
        id = vertex['_id']; vertex.delete '_id'
        create_vertex id, vertex
      end
      data['edges'].each_pair do |_id, edge|
        if edge['_type'] != 'edge'
          if edge['label'] or edge['label'].nil?
            next
          end
        end
        edge.delete '_type'
        # If present, remove the vertex ID/label/out_v/in_v and use all other 
        # properties as edge properties
        id = edge['_id']; edge.delete '_id'
        label = edge['label']; edge.delete 'label'
        out_v = edge['out_v']; edge.delete 'out_v'
        in_v = edge['in_v']; edge.delete 'in_v'
        new_edge = create_edge id, vertex(out_v), vertex(in_v), label
        new_edge.properties = edge
      end
      true
    end
    
    # Return the graph in JSON format in a string.  If you do this on a large graph, KABOOM.
    def to_json
      json_graph = {}
      # Generate an array of vertices, keyed by ID, filled with properties
      #
      # Conforms roughly with Rexster format.  See GraphML format example:
      #
      # <node id="33">
      #   <data key="address">serena.bishop@enron.com</data>
      #   <data key="type">email</data>
      # </node>
      json_graph[:vertices] = {}
      self.v.each do |v| 
        json_graph[:vertices][v.id.to_i] = v.properties.merge( {'_type' => 'vertex', '_id' => v.id.to_i} )
      end
      
      # Generate an array of edges, keyed by ID, filled with in_v/out_v and properties
      #
      # Conforms roughly to Rexster format.  See GraphML format example:
      #
      # <edge id="162582" source="41" target="1718" label="sent">
      #   <data key="volume">3</data>
      # </edge>
      json_graph[:edges] = {}
      self.e.each do |e|
        edge = e.properties.merge( {'_type' => 'edge',
       	 	 													'_id' => e.id.to_i,
                                    'label' => e.first.get_label,
                                    'in_v' => e.in_v.first.id, 
                                    'out_v' => e.out_v.first.id
                                  } )    
        json_graph[:edges][e.id.to_i] = edge
      end
      
      JSON json_graph
    end
    
    # Create and return an n degree k-core for the graph.  
    # See http://en.wikipedia.org/wiki/K-core
    def k_core(k)      
      k_nodes = self.v.filter{|v| v.out_e.count > k}.result
			k_nodes.out_e.in_v.only(k_nodes).subgraph
    end

    # Set how many elements should go into each transaction in a bulk
    # job.
    #
    # @param [Fixnum] size number of elements
    def bulk_job_size=(size)
      @bulk_job_size = size
    end

    # The currently configured bulk job size.
    def bulk_job_size
      @bulk_job_size || 5000
    end

    # Are we currently in the midst of a bulk job?
    def in_bulk_job?
      @in_bulk_job
    end

    # Directly loads an array of vertices by id.
    #
    # @param [[vertex ids]] ids
    # @return [[Pacer::VertexMixin]]
    def load_vertices(ids)
      ids.map do |id|
        vertex id
      end.compact
    end

    # Directly loads an array of edges by id.
    #
    # @param [[edge ids]] ids
    # @return [[Pacer::EdgeMixin]]
    def load_edges(ids)
      ids.map do |id|
        edge id
      end.compact
    end

    # Return an index by name.
    #
    # @param [#to_s] name of the index
    # @param [:vertex, :edge, element type] type guarantees that the index returned is of the type specified.
    # @param [Hash] opts
    # @option opts [true] :create create the index if it doesn't exist
    # @return [Pacer::IndexMixin]
    def index_name(name, type = nil, opts = {})
      name = name.to_s
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

    # Drops and recreates an automatic index with the same keys.
    #
    # In some earlier graphdb versions it was possible to corrupt
    # automatic indices. This method provided a fast way to recreate
    # them.
    #
    # @param [Index] old_index this index will be dropped
    # @return [Index] rebuilt index
    def rebuild_automatic_index(old_index)
      name = old_index.getIndexName
      index_class = old_index.getIndexClass
      keys = old_index.getAutoIndexKeys
      drop_index name
      build_automatic_index(name, index_class, keys)
    end

    # Creates a new automatic index.
    #
    # @param [#to_s] name index name
    # @param [:vertex, :edge, element type] et element type
    # @param [[#to_s], nil] keys The keys to be indexed. If nil then
    #   index all keys
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

    # The current graph
    #
    # @return [Graph] returns self
    def graph
      self
    end

    # The proc used to name vertices.
    #
    # @return [Proc]
    def vertex_name
      @vertex_name
    end

    # Set the proc used to name vertices.
    #
    # @param [Proc(vertex)] a_proc returns a string given a vertex
    def vertex_name=(a_proc)
      @vertex_name = a_proc
    end

    # The proc used to name edges.
    #
    # @return [Proc]
    def edge_name
      @edge_name
    end

    # Set the proc used to name edges.
    #
    # @param [Proc(edge)] a_proc returns a string given an edge
    def edge_name=(a_proc)
      @edge_name = a_proc
    end

    # Return an object that can be compared to the return value of
    # Index#index_class.
    def index_class(et)
      element_type(et).java_class.to_java
    end

    # Is the element type given supported by this graph?
    #
    # @param [:edge, :vertex, :mixed, element_type, Object] et the
    #   object we're testing
    def element_type?(et)
      if [element_type(:vertex), element_type(:edge), element_type(:mixed)].include?  element_type(et)
        true
      else
        false
      end
    end

    # Does this graph support edges where the in_vertex and the
    # out_vertex are the same?
    #
    # Specific graphs may override this method to return false.
    def supports_circular_edges?
      true
    end

    # When creating an element, does this graph allow me to specify the
    # element_id?
    #
    # Specific graphs may override this method to return false.
    def supports_custom_element_ids?
      true
    end

    # Does this graph allow me to create or modify automatic indices?
    #
    # Specific graphs may override this method to return false.
    def supports_automatic_indices?
      true
    end

    # Does this graph allow me to create or modify manual indices?
    #
    # Specific graphs may override this method to return false.
    def supports_manual_indices?
      true
    end

    # Does this graph support indices on edges?
    #
    # Specific graphs may override this method to return false.
    def supports_edge_indices?
      true
    end

    protected

    # Helper method to wrap element creation in exception handling.
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
