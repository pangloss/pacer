module Pacer::Wrappers
  class VertexWrapper < ElementWrapper
    include Pacer::Vertex
    include Pacer::Core::Graph::VerticesRoute

    def_delegators :@element,
      # Object
      :equals, :toString, :hashCode,
      # Element
      :getId, :getPropertyKeys, :getProperty, :setProperty, :removeProperty, :getRawElement,
      # Vertex
      :getEdges, :getVertices, :query, :getRawVertex

    class << self
      def wrappers
        @wrappers ||= {}
      end

      def wrapper_for(exts)
        if exts
          base_vertex_wrapper.wrappers[exts.to_set] ||= build_vertex_wrapper(exts)
        else
          fail Pacer::LogicError, "Extensions should not be nil"
        end
      end

      def clear_cache
        @wrappers = {}
      end

      protected

      def build_vertex_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Vertex], base_vertex_wrapper)
      end
    end

    # This method must be defined here rather than in the superclass in order
    # to correctly override the method in an included module
    attr_reader :element

    # This method must be defined here rather than in the superclass in order
    # to correctly override the method in an included module
    def extensions
      self.class.extensions
    end

    # Add extensions to this vertex.
    #
    # If any extension has a Vertex module within it, this vertex will
    # be extended with the extension's Vertex module.
    #
    # @param [[extensions]] exts the extensions to add
    # @return [Pacer::EdgeWrapper] this vertex wrapped up and including
    #   the extensions
    def add_extensions(exts)
      if exts.any?
        self.class.wrap(self, extensions + exts.to_a)
      else
        self
      end
    end

    # Returns the element with a new simple wrapper.
    # @return [VertexWrapper]
    def no_extensions
      self.class.base_vertex_wrapper.new graph, element
    end

    # Checks that the given extensions can be applied to the vertex. If
    # they can then yield the vertex correctly extended or return the extended
    # vertex. If not then do not yield and return nil.
    #
    # @param [extensions] exts extensions to add if possible
    # @yield [v] Optional block yields the vertex with the extensions added.
    # @return nil or the result of the block or the extended vertex
    def as(*exts)
      if exts.length == 1 and not exts.first.is_a?(Module) and not exts.first.is_a?(Class) and exts.first
        # NB: oops, I defined route#as to be the same as route#section. If the signature is
        #     matching the section method, then defer to it.
        section exts.first
      elsif as?(*exts)
        exts_to_add = extensions_missing(exts)
        extended = exts_to_add.empty? ? self : add_extensions(exts_to_add)
        if block_given?
          yield extended
        else
          extended
        end
      end
    end

    def only_as(*exts)
      if as?(*exts)
        extended = exts.empty? ? no_extensions : no_extensions.add_extensions(exts)
        if block_given?
          yield extended
        else
          extended
        end
      end
    end

    def as?(*exts)
      extensions_missing(exts).all? do |ext|
        rc = if ext.respond_to? :route_conditions
               ext.route_conditions(graph)
             elsif ext.respond_to? :lookup
               ext.lookup(graph)
             end
        if rc
          rc.all? do |k, v|
            if v.is_a? Set
              v.include? self[k]
            else
              self[k] == v
            end
          end
        else
          true
        end
      end
    end

    # Returns a human-readable representation of the vertex using the
    # standard ruby console representation of an instantiated object.
    # @return [String]
    def inspect
      graph.read_transaction do
        "#<#{ ["V[#{element_id}]", display_name].compact.join(' ') }>"
      end
    end

    # Returns the display name of the vertex.
    # @return [String]
    def display_name
      graph.vertex_name.call self if graph and graph.vertex_name
    end

    # Deletes the vertex from its graph along with all related edges.
    def delete!
      graph.remove_vertex element
    end

    # Copies including the vertex id unless a vertex with that id
    # already exists.
    # @param [PacerGraph] target_graph
    # @param opts for compatibility with {Pacer::Wrappers::EdgeWrapper#clone_into}
    # @yield [v] Optional block yields the vertex after it has been created.
    # @return [Pacer::Wrappers::VertexWrapper] the new vertex
    def clone_into(target_graph, opts = nil)
      v_idx = target_graph.temp_index("tmp-v-#{graph.graph_id}", :vertex, :create => true)
      v = v_idx.first('id', element_id)
      unless v
        v = target_graph.create_vertex element_id, properties
        v_idx.put('id', element_id, v.element)
        yield v if block_given?
      end
      v
    end

    # Make a new copy of the element with the next available vertex id.
    #
    # @param [PacerGraph] target_graph
    # @yield [v] Optional block yields the vertex after it has been created.
    # @return [Pacer::Wrappers::VertexWrapper] the new vertex
    def copy_into(target_graph)
      v = target_graph.create_vertex properties
      yield v if block_given?
      v
    end

    def out_edges(*labels_and_extensions)
      get_edges_helper Pacer::Pipes::OUT, *labels_and_extensions
    end

    def in_edges(*labels_and_extensions)
      get_edges_helper Pacer::Pipes::IN, *labels_and_extensions
    end

    def both_edges(*labels_and_extensions)
      get_edges_helper Pacer::Pipes::BOTH, *labels_and_extensions
    end

    def out_vertices(*labels_and_extensions)
      get_vertices_helper Pacer::Pipes::OUT, *labels_and_extensions
    end

    def in_vertices(*labels_and_extensions)
      get_vertices_helper Pacer::Pipes::IN, *labels_and_extensions
    end

    def both_vertices(*labels_and_extensions)
      get_vertices_helper Pacer::Pipes::BOTH, *labels_and_extensions
    end

    # Test equality to another object.
    #
    # Elements are equal if they are the same type and have the same id
    # and the same graph, regardless of extensions.
    #
    # If the graphdb instantiates multiple copies of the same element
    # this method will return true when comparing them.
    #
    # If the other instance is an unwrapped vertex, this will always return
    # false because otherwise the == method would not be symetrical.
    #
    # @param other
    def ==(other)
      other.is_a? VertexWrapper and
        element_id == other.element_id and
        graph == other.graph
    end
    alias eql? ==

    # Neo4j and Orient both have hash collisions between vertices and
    # edges which causes problems when making a set out of a path for
    # instance. Simple fix: negate edge hashes.
    def hash
      element.hash
    end

    def element_payload=(data)
      if element.is_a? Pacer::Payload::Vertex
        element.payload = data
      else
        @element = Pacer::Payload::Vertex.new element, data
      end
    end

    protected

    def get_edges_helper(direction, *labels_and_extensions)
      labels, exts = split_labels_and_extensions(labels_and_extensions)
      pipe = Pacer::Pipes::WrappingPipe.new graph, :edge, exts
      pipe.setStarts element.getEdges(direction, *labels).iterator
      pipe
    end

    def get_vertices_helper(direction, *labels_and_extensions)
      labels, exts = split_labels_and_extensions(labels_and_extensions)
      pipe = Pacer::Pipes::WrappingPipe.new graph, :vertex, exts
      pipe.setStarts element.getVertices(direction, *labels).iterator
      pipe
    end

    def split_labels_and_extensions(mixed)
      labels = Set[]
      exts = []
      mixed.each do |obj|
        if obj.is_a? Symbol
          labels << obj.to_s
        elsif obj.is_a? String
          labels << obj
        else
          exts << obj
        end
      end
      [labels, exts.uniq]
    end

    # Return the extensions this vertex is missing from the given array
    def extensions_missing(exts)
      Set.new(exts.flatten).difference extensions.to_set
    end
  end
end
