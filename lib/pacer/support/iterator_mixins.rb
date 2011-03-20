module Pacer::Core::Route
  # This mixin allows an iterator to be returned from methods that perform a
  # transformation on the elements in their collection. Set the block property
  # to the proc that does the transformation.
  module IteratorBlockMixin
    attr_accessor :graph

    # Set the block that does the transformation.
    def block=(block)
      @block = block
    end

    def next
      item = super
      item.graph ||= @graph
      @block.call(item)
    end
  end

  module IteratorContextMixin
    attr_accessor :graph

    # Set the context
    def context=(context)
      @context = context
    end

    def next
      item = super
      item.back = @context
      item.graph ||= @graph
      item
    end
  end

  module IteratorPathMixin
    attr_accessor :graph

    def next
      path = super
      path.each do |e|
        e.graph ||= @graph rescue nil
      end
      path
    end
  end

  module IteratorExtensionsMixin
    attr_accessor :graph

    # Set the extensions
    def extensions=(extensions)
      @extensions = extensions
    end

    def next
      item = super
      item.add_extensions @extensions
      item.graph ||= @graph
      item
    end
  end
end
