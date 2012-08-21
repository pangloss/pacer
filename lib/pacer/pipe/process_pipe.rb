module Pacer::Pipes
  class ProcessPipe < AbstractPipe
    field_reader :starts
    attr_reader :is_element, :extensions, :back, :block, :graph

    def initialize(back, block)
      super()
      @block = Pacer::Wrappers::WrappingPipeFunction.new back, block
    end

    def processNextStart
      while true
        obj = starts.next
        block.call(obj)
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
