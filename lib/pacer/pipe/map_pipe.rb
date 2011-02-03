module Pacer::Pipes
  class MapPipe < AbstractPipe
    field_reader :starts

    def initialize(back, block)
      super()
      @block = block
      @back = back
      @graph = back.graph if back
      @extensions = back.extensions + [Pacer::Extensions::BlockFilterElement]
      @is_element = @graph.element_type?(back.element_type) if @graph
    end

    def processNextStart
      while true
        obj = starts.next
        begin
          if @is_element
            obj = obj.add_extensions(@extensions)
            obj.back = @back
            obj.graph = @back.graph
          end
        rescue
        end
        result = @block.call(obj)
        return result
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
