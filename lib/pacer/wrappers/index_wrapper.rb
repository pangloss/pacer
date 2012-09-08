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
      WrapperSelector.build element_type
    end

    def first(key, value, extensions = nil)
      e = index.get(key, value).first
      if e
        e = wrapper.new graph, e
        e = e.add_extensions extensions if extensions
      end
      e
    end

    def all(key, value, extensions = nil)
      iter = index.get(key, value)
      if graph or extensions
        pipe = Pacer::Pipes::WrappingPipe.new graph, element_type, extensions
        pipe.setStarts iter.iterator
        pipe
      else
        iter
      end
    end

    def put(key, value, element)
      if element.is_a? ElementWrapper
        element = element.element
      end
      index.put key, value, element
    end
  end
end
