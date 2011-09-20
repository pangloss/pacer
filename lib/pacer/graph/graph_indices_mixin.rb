module Pacer
  module GraphIndicesMixin
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
        idx = getIndices.detect { |i| i.index_name == name and i.index_class == index_class(type) }
        if idx.nil? and opts[:create]
          idx = createManualIndex name, element_type(type)
        end
      else
        idx = getIndices.detect { |i| i.index_name == name }
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
      index.graph = self
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

    # Return an object that can be compared to the return value of
    # Index#index_class.
    def index_class(et)
      element_type(et).java_class.to_java
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
  end
end
