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
      WrapperSelector.build graph, element_type
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
      modify(key, value, element, :put)
    end

    def remove(key, value, element)
      modify(key, value, element, :remove)
    end

    protected

    LEGAL_MODIFICATIONS = Set.new([:put, :remove])

    def modify(key, value, element, modification)
      if LEGAL_MODIFICATIONS.include?(modification)
        if element.is_a? ElementWrapper
          element = element.element
        end
        key_string = key.to_s

        index.send modification, key.to_s, value, element
      else
        raise "Illegal modification: #{modification}"
      end
    end
  end
end
