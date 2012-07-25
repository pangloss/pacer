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
          idx = createIndex name, element_type(type)
        end
      else
        idx = getIndices.detect { |i| i.index_name == name }
      end
      idx.graph = self if idx
      idx
    end



    # Return an object that can be compared to the return value of
    # Index#index_class.
    def index_class(et)
      element_type(et).java_class.to_java
    end
  end
end
