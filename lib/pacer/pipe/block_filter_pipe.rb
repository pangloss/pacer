module Pacer::Pipes
  class BlockFilterPipe < RubyPipe
    def initialize(starts, back, block)
      super()
      set_starts(starts)
      @back = back
      @block = block
      @graph = back.graph

      @extensions = @back.extensions + [Pacer::Extensions::BlockFilterElement]
    end

    def processNextStart()
      while raw_element = @starts.next
        extended_element = raw_element.add_extensions(@extensions)
        extended_element.back = @back
        extended_element.graph = @back.graph if extended_element.respond_to? :graph=
        ok = @block.call extended_element
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
