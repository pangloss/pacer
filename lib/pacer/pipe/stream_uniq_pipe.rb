module Pacer::Pipes
  class StreamUniqPipe < RubyPipe
    def initialize(buffer = 1000)
      super()
      @list = java.util.LinkedList.new
      @buffer = buffer
    end

    protected

    def processNextStart
      while true
        obj = @starts.next
        duplicate = @list.removeLastOccurrence(obj)
        @list.addLast obj
        if not duplicate
          if @buffer == 0
            @list.removeFirst
          else
            @buffer -= 1
          end
          return obj
        end
      end
    rescue NativeException => e
      if e.cause.getClass == NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
