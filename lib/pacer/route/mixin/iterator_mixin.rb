module Pacer::Routes

  # This module needs to be mixed in to the iterator if it is returned raw from
  # a route, for example when using the #to_enum method. It ensures that the returned
  # elements are correctly set up so that their extensions work.
  module IteratorGraphMixin
    # Set the graph that the elements will be returned from.
    def graph=(graph)
      @graph = graph
    end

    def next
      item = super
      item.graph = @graph
      item
    end
  end

  # This mixin allows an iterator to be returned from methods that perform a
  # transformation on the elements in their collection. Set the block property
  # to the proc that does the transformation.
  module IteratorBlockMixin
    # Set the block that does the transformation.
    def block=(block)
      @block = block
    end

    def next
      @block.call(super)
    end
  end

  module IteratorContextMixin
    # Set the context
    def context=(context)
      @context = context
    end

    def next
      item = super
      item.back = @context
      item
    end
  end
end
