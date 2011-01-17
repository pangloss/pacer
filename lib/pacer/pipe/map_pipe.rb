module Pacer::Pipes
  class MapPipe < RubyPipe
    def initialize(back, block)
      super()
      @block = block
      @back = back
      @graph = back.graph
      @extensions = back.extensions + [Pacer::Extensions::BlockFilterElement]
      @is_element = @graph.element_type?(back.element_type)
    end

    def processNextStart
      while true
        obj = @starts.next
        if @is_element
          obj = obj.add_extensions(@extensions)
          obj.back = @back
          obj.graph = @back.graph
        end
        return @block.call(obj)
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
