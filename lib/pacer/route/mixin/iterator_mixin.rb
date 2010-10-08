module Pacer::Routes
  module IteratorMixin
    def graph=(graph)
      @graph = graph
    end

    def next
      item = super
      item.graph = @graph
      item
    end
  end
end
