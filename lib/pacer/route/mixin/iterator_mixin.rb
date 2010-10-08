module Pacer::Routes
  module IteratorGraphMixin
    def graph=(graph)
      @graph = graph
    end

    def next
      item = super
      item.graph = @graph
      item
    end
  end

  module IteratorBlockMixin
    def block=(block)
      @block = block
    end

    def next
      @block.call(super)
    end
  end
end
