module Pacer::Pipes
  class BlockFilterPipe < AbstractPipe
    field_reader :starts

    def initialize(back, block, invert = false)
      super()
      @back = back
      @block = block
      @graph = back.graph
      @invert = invert

      @extensions = @back.extensions + [Pacer::Extensions::BlockFilterElement]
      @is_element = @graph.element_type?(back.element_type) if @graph
    end

    def processNextStart()
      while raw_element = starts.next
        if @is_element
          extended_element = raw_element.add_extensions(@extensions)
          extended_element.back = @back
          extended_element.graph = @back.graph
          ok = @block.call extended_element
        else
          ok = @block.call raw_element
        end
        ok = !ok if @invert
        return raw_element if ok
      end
      raise Pacer::NoSuchElementException
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
