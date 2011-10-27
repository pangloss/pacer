module Pacer::Pipes
  class ProcessPipe < AbstractPipe
    field_reader :starts
    attr_reader :is_element, :extensions, :back, :block, :graph

    def initialize(back, block)
      super()
      @block = block
      @back = back
      @graph = back.graph if back
      @extensions = back.extensions + [Pacer::Extensions::BlockFilterElement]
      @is_element = graph.element_type?(back.element_type) if graph
    end

    def processNextStart
      while true
        obj = starts.next
        begin
          if is_element
            obj = obj.add_extensions(extensions)
            obj.back = back
            obj.graph = graph
          end
        rescue
        end
        result = block.call(obj)
        return obj
      end
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
