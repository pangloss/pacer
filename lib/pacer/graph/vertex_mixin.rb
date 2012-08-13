module Pacer
  # This module is mixed into the raw Blueprints Vertex class from any
  # graph implementation.
  #
  # Adds more convenient/rubyish methods and adds support for extensions
  # to some methods where needed.
  module VertexMixin
    # Add extensions to this vertex.
    #
    # If any extension has a Vertex module within it, this vertex will
    # be extended with the extension's Vertex module.
    #
    # @see Core::Route#add_extension
    #
    # @param [[extensions]] exts the extensions to add
    # @return [Pacer::EdgeWrapper] this vertex wrapped up and including
    #   the extensions
    def add_extensions(exts)
      if exts.any?
        Wrappers::VertexWrapper.wrap(self, exts)
      else
        self
      end
    end

    # Checks that the given extensions can be applied to the vertex. If
    # they can then yield the vertex correctly extended or return the extended
    # vertex. If not then do not yield and return nil.
    #
    # @param [extensions] exts extensions to add if possible
    # @yield [v] Optional block yields the vertex with the extensions added.
    # @return nil or the result of the block or the extended vertex
    def as(*exts)
      if as?(*exts)
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
        extended = exts.empty? ? element : element.add_extensions(exts)
        if block_given?
          yield extended
        else
          extended
        end
      end
    end

    def as?(*exts)
      has_exts = extensions_missing(exts).all? do |ext|
        if ext.respond_to? :route_conditions
          ext.route_conditions.all? do |k, v|
            self[k] == v
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
      "#<#{ ["V[#{element_id}]", display_name].compact.join(' ') }>"
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
    # @param opts for compatibility with {Pacer::EdgeMixin#clone_into}
    # @yield [v] Optional block yields the vertex after it has been created.
    # @return [Pacer::VertexMixin] the new vertex
    def clone_into(target_graph, opts = nil)
      v_idx = target_graph.index_name("tmp:v:#{graph.to_s}", :vertex, :create => true)
      v = target_graph.vertex(element_id) || v_idx.get('id', element_id).first
      unless v
        v = target_graph.create_vertex element_id, properties
        v_idx.put('id', element_id, v)
        yield v if block_given?
      end
      v
    end

    # Make a new copy of the element with the next available vertex id.
    #
    # @param [PacerGraph] target_graph
    # @yield [v] Optional block yields the vertex after it has been created.
    # @return [Pacer::VertexMixin] the new vertex
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

    protected

    def get_edges_helper(direction, *labels_and_extensions)
      labels, exts = split_labels_and_extensions(labels_and_extensions)
      edge_iterator(element.getEdges(direction, *labels).iterator, exts)
    end

    def split_labels_and_extensions(mixed)
      labels = Set[]
      exts = Set[]
      mixed.each do |obj|
        if obj.is_a? Symbol or obj.is_a? String
          labels << obj
        else
          exts << obj
        end
      end
      [labels, exts]
    end

    def edge_iterator(iter, exts)
      iter.extend Pacer::Core::Route::IteratorExtensionsMixin
      iter.graph = self.graph
      iter.extensions = exts
      iter
    end

    # Return the extensions this vertex is missing from the given array
    def extensions_missing(exts)
      Set.new(exts).difference extensions.to_set
    end
  end
end
