module Pacer::Pipes
  class MapPipe < AbstractPipe
    field_reader :starts

    attr_reader :block

    def initialize(back, block)
      super()
      @block = Pacer::Wrappers::WrappingPipeFunction.new back, block
      @block = Pacer::Wrappers::UnwrappingPipeFunction.new @block
    end

    def processNextStart
      while true
        obj = starts.next
        return block.call(obj)
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
