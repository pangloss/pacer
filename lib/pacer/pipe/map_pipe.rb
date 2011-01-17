module Pacer::Pipes
  class MapPipe < RubyPipe
    def initialize(block)
      super()
      @block = block
    end

    def processNextStart
      while true
        obj = @starts.next
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
