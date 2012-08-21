module Pacer::Wrappers
  class IndexWrapper
    attr_reader :index, :graph, :element_type

    def initialize(graph, index, element_type)
      @index = index
      @graph = graph
      @element_type = element_type
    end

    def name
      index.index_name
    end

    def wrapper
      Pacer::WrapperSelector.build element_type
    end

    def first(key, value, extensions = nil)
      e = index.get(key, value).first
      if e
        e = wrapper.new e
        e = e.add_extensions extensions if extensions
        e.graph = graph
      end
      e
    end

    def all(key, value, extensions = nil)
      iter = index.get(key, value)
      if graph or extensions
        iter.extend Pacer::Core::Route::IteratorExtensionsMixin
        iter.graph = graph
        iter.extensions = extensions
      end
      iter
    end
  end
end
