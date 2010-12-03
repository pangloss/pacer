module Pacer::Routes
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

  module IteratorExtensionsMixin
    # Set the extensions
    def extensions=(extensions)
      @extensions = extensions
    end

    def next
      item = super
      item.add_extensions @extensions
      item
    end
  end
end
