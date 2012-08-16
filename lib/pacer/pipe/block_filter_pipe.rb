module Pacer::Pipes
  class BlockFilterPipe < AbstractPipe
    field_reader :starts

    attr_reader :block

    def initialize(back, block, invert = false)
      super()
      @block = Pacer::Wrappers::WrappingPipeFunction.new back, block
    end

    def processNextStart()
      while raw_element = starts.next
        ok = block.call raw_element
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
