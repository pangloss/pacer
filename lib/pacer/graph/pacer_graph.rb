module Pacer
  class PacerGraph
    include GraphTransactionsMixin

    include Pacer::Core::Route
    include Pacer::Core::Graph::GraphRoute
    include Pacer::Core::Graph::GraphIndexRoute

    attr_reader :blueprints_graph, :encoder

    attr_accessor :base_vertex_wrapper, :base_edge_wrapper

    def initialize(encoder, open, shutdown = nil, graph_id = nil)
      self.base_vertex_wrapper = Pacer::Wrappers::VertexWrapper
      self.base_edge_wrapper = Pacer::Wrappers::EdgeWrapper
      if open.is_a? Proc
        @reopen = open
      else
        @reopen = proc { open }
      end
      @shutdown = shutdown
      reopen
      @encoder = encoder
      @graph_id = graph_id
    end

    # The current graph
    #
    # @return [PacerGraph] returns self
    def graph
      self
    end

    def vendor(full = false)
      g = blueprints_graph
      g = g.raw_graph if g.respond_to? :raw_graph
      if full
        g.java_class.name
      else
        g.java_class.name.split('.')[1]
      end
    end

    def reopen
      @blueprints_graph = unwrap_graph @reopen.call
      self
    end

    def shutdown
      @shutdown.call self if @shutdown
      @blueprints_graph = nil
      self
    end

    def copy_object
      self.class.new @encoder, @reopen, @shutdown, graph_id
    end

    def use_wrapper(klass)
      reopen = proc do
        klass.new unwrap_graph(@reopen.call)
      end
      PacerGraph.new encoder, reopen, @shutdown
    end

    def use_encoder(encoder)
      PacerGraph.new encoder, @reopen, @shutdown
    end

    def graph_id
      @graph_id ||= blueprints_graph.object_id
    end

    def equals(other)
      other.class == self.class and graph_id == other.graph_id
    end

    # Get a vertex by id.
    #
    # @overload vertex(id)
    #   @param [element id] id
    # @overload vertex(id, *modules)
    #   @param [element id] id
    #   @param [Module, Class] *modules extensions to add to the returned
    #     vertex.
    def vertex(id, *modules)
      begin
        v = blueprints_graph.getVertex(id)
      rescue java.lang.RuntimeException
      end
      if v
        wrapper = modules.detect { |obj| obj.ancestors.include? Pacer::Wrappers::VertexWrapper }
        if wrapper
          v = wrapper.new graph, v
          modules.delete wrapper
        else
          v = base_vertex_wrapper.new graph, v
        end
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
      begin
        v = blueprints_graph.getEdge(id)
      rescue Java::JavaLang::RuntimeException
      end
      if v
        wrapper = modules.detect { |obj| obj.ancestors.include? Pacer::Wrappers::EdgeWrapper }
        if wrapper
          v = wrapper.new graph, v
          modules.delete wrapper
        else
          v = base_edge_wrapper.new graph, v
        end
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
      id, wrapper, modules, props = id_modules_properties(args)
      raw_vertex = creating_elements { blueprints_graph.addVertex(id) }
      if wrapper
        vertex = wrapper.new graph, raw_vertex
      else
        vertex = base_vertex_wrapper.new graph, raw_vertex
      end
      if modules.any?
        vertex = vertex.add_extensions modules
      end
      props.each { |k, v| vertex[k.to_s] = v } if props
      vertex
    end

    # Create an edge in the graph.
    #
    # @param [element id] id some graphs allow you to specify your own edge id.
    # @param [Pacer::Wrappers::VertexWrapper] from_v the new edge's out_vertex
    # @param [Pacer::Wrappers::VertexWrapper] to_v the new edge's in_vertex
    # @param [#to_s] label the edge label
    # @param [extension, Hash] *args extension (Module/Class) arguments will be
    #   added to the returned edge. A Hash will be
    #   treated as element properties.
    #
    # @todo make id param optional
    def create_edge(id, from_v, to_v, label, *args)
      _, wrapper, modules, props = id_modules_properties(args)
      raw_edge = creating_elements { blueprints_graph.addEdge(id, from_v.element, to_v.element, label.to_s) }
      if wrapper
        edge = wrapper.new graph, raw_edge
      else
        edge = base_edge_wrapper.new graph, raw_edge
      end
      if modules.any?
        edge = edge.add_extensions modules
      end
      props.each { |k, v| edge[k.to_s] = v } if props
      edge
    end

    def remove_vertex(vertex)
      blueprints_graph.removeVertex vertex
    end

    def remove_edge(edge)
      blueprints_graph.removeEdge edge
    end

    # Directly loads an array of vertices by id.
    #
    # @param [[vertex ids]] ids
    # @return [[Pacer::Wrappers::VertexWrapper]]
    def load_vertices(ids)
      ids.map do |id|
        vertex id
      end.compact
    end

    # Directly loads an array of edges by id.
    #
    # @param [[edge ids]] ids
    # @return [[Pacer::Wrappers::EdgeWrapper]]
    def load_edges(ids)
      ids.map do |id|
        edge id
      end.compact
    end

    def features
      blueprints_graph.features
    end

    def inspect
      "#<PacerGraph #{ blueprints_graph.to_s }"
    end


    private

    def unwrap_graph(graph)
      if graph.is_a? PacerGraph
        graph.blueprints_graph
      else
        graph
      end
    end




    public

    module Encoding
      def encode_property(value)
        encoder.encode_property value
      end

      def decode_property(value)
        encoder.decode_property value
      end
    end
    include Encoding

    module Naming
      # The proc used to name vertices.
      #
      # @return [Proc] returns a string given a vertex
      attr_accessor :vertex_name

      # The proc used to name edges.
      #
      # @return [Proc] returns a string given an edge
      attr_accessor :edge_name
    end
    include Naming

    module BulkJob
      attr_accessor :in_bulk_job

      # Set how many elements should go into each transaction in a bulk
      # job.
      #
      # @param [Fixnum] size number of elements
      def bulk_job_size=(size)
        @bulk_job_size = size
      end

      # The currently configured bulk job size.
      def bulk_job_size
        if defined? @bulk_job_size
          @bulk_job_size
        else
          5000
        end
      end

      # Are we currently in the midst of a bulk job?
      def in_bulk_job?
        @in_bulk_job if defined? @in_bulk_job
      end
    end
    include BulkJob

    module Indices
      # Return an index by name.
      #
      # @param [#to_s] name of the index
      # @param [:vertex, :edge, element type] type guarantees that the index returned is of the type specified.
      # @param [Hash] opts
      # @option opts [true] :create create the index if it doesn't exist
      # @return [Pacer::IndexMixin]
      def index(name, type = nil, opts = {})
        return temp_index(name, type, opts) unless features.supportsIndices
        name = name.to_s
        if type
          type = index_class element_type type
          idx = blueprints_graph.getIndices.detect { |i| i.index_name == name }
          if idx.nil? and opts[:create]
            idx = blueprints_graph.createIndex name, type
          end
        else
          idx = blueprints_graph.getIndices.detect { |i| i.index_name == name }
        end
        Pacer::Wrappers::IndexWrapper.new self, idx, type if idx
      end

      def drop_index(idx)
        return drop_temp_index(idx) unless features.supportsIndices
        if idx.is_a? String or idx.is_a? Symbol
          blueprints_graph.dropIndex idx
        else
          blueprints_graph.dropIndex idx.indexName
        end
      end

      def temp_index(name, type = nil, opts = {})
        @temp_indices ||= {}
        idx = @temp_indices[name]
        unless idx
          if opts[:temp] != false
            if name and type and opts[:create]
              idx = @temp_indices[name] = Pacer::Graph::HashIndex.new type, name
            elsif opts[:create]
              idx = Pacer::Graph::HashIndex.new type, nil
            end
          end
        end
        Pacer::Wrappers::IndexWrapper.new self, idx, idx.type if idx
      end

      def drop_temp_index(idx)
        @temp_indices.delete idx.name
      end

      def drop_temp_indices
        @temp_indices = {}
      end

      # Return an object that can be compared to the return value of
      # Index#index_class.
      def index_class(et)
        type = case et
               when :vertex
                 Pacer::Vertex
               when :edge
                 Pacer::Edge
               else
                 fail InternalError, "Unable to determine index class from #{ et.inspect }"
               end
        type.java_class.to_java
      end

      def index_class?(et, thing)
        if thing.interface?
          index_class(et) == thing
        else
          thing.interfaces.include? index_class(et)
        end
      end

      def indices
        if features.supportsIndices
          blueprints_graph.getIndices
        else
          []
        end
      end
    end
    include Indices

    module KeyIndices
      def create_key_index(name, type)
        if features.supportsKeyIndices
          if element_type(type) == :vertex and features.supportsVertexKeyIndex
            blueprints_graph.createKeyIndex name.to_s, index_class(:vertex)
          elsif element_type(type) == :edge and features.supportsEdgeKeyIndex
            blueprints_graph.createKeyIndex name.to_s, index_class(:edge)
          end
        end
      end

      def drop_key_index(name, type = :vertex)
        if features.supportsKeyIndices
          if element_type(type) == :vertex and features.supportsVertexKeyIndex
            blueprints_graph.dropKeyIndex name.to_s, index_class(:vertex)
          elsif element_type(type) == :edge and features.supportsEdgeKeyIndex
            blueprints_graph.createKeyIndex name.to_s, index_class(:edge)
          end
        end
      end

      def key_indices(type = nil)
        if features.supportsKeyIndices
          if type
            blueprints_graph.getIndexedKeys(index_class(type)).to_set
          else
            blueprints_graph.getIndexedKeys(index_class(:vertex)).to_set +
              blueprints_graph.getIndexedKeys(index_class(:vertex))
          end
        else
          []
        end
      end

      def vertices_by_key(key, value, *extensions)
        if key_indices(:vertex).include? key.to_s
          pipe = Pacer::Pipes::WrappingPipe.new self, :vertex, extensions
          pipe.setStarts blueprints_graph.getVertices(key.to_s, value).iterator
          pipe
        else
          fail ClientError, "The key #{ key } is not indexed"
        end
      end

      def edges_by_key(key, value, *extensions)
        if key_indices(:edge).include? key.to_s
          pipe = Pacer::Pipes::WrappingPipe.new self, :edge, extensions
          pipe.setStarts blueprints_graph.getEdges(key.to_s, value).iterator
          pipe
        else
          fail ClientError, "The key #{ key } is not indexed"
        end
      end
    end
    include KeyIndices

    module ElementType
      # Is the element type given supported by this graph?
      #
      # @param [:edge, :vertex, :mixed, element_type, Object] et the
      #   object we're testing
      def element_type?(et)
        [:vertex, :edge, :mixed].include?  element_type(et)
      end

      def element_type(et = nil)
        return nil unless et
        result = case et
                 when :vertex, Pacer::Vertex
                   :vertex
                 when :edge, Pacer::Edge
                   :edge
                 when :mixed, Pacer::Element
                   :mixed
                 when :object
                   :object
                 else
                   if et == Object
                     :object
                   elsif et == index_class(:vertex)
                     :vertex
                   elsif et == index_class(:edge)
                     :edge
                   end
                 end
        if result
          result
        else
          raise ArgumentError, 'Element type may be one of :vertex, :edge, :mixed or :object'
        end
      end
    end
    include ElementType

    private

    def id_modules_properties(args)
      props = args.last if args.last.is_a? Hash
      modules = args.select { |obj| obj.is_a? Module or obj.is_a? Class }
      wrapper = modules.detect { |obj| obj.is_a? Class and obj.ancestors.include? Pacer::Wrappers::ElementWrapper }
      id = args.first
      if not wrapper and modules.empty?
        args.each do |obj|
          if obj.respond_to? :wrapper
            wrapper = obj.wrapper
            id = nil if id == obj
            break
          elsif obj.respond_to? :parts
            modules = obj.parts
            id = nil if id == obj
            break
          end
        end
      end
      modules.delete wrapper
      begin
        id = nil if id == props or modules.include? id or id == wrapper
      rescue Exception
        # Orient uses an ID type that can't be compared with things?
      end
      [id, wrapper, modules, props]
    end

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

    def source_iterator
      [blueprints_graph]
    end
  end
end
