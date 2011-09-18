module Pacer::Pipes
  class IsEmptyPipe < RubyPipe
    def initialize
      super
      @raise = false
    end

    def processNextStart
      raise Pacer::NoSuchElementException if @raise
      @starts.next
    rescue NativeException => e
      if e.cause.getClass == NoSuchElementException.getClass
        # This is the only case where we return true.
        # The only time we get here is if the first call to next
        # has no results.
        true
      else
        raise e
      end
    else
      @raise = true
      raise Pacer::NoSuchElementException
    end

    def reset
      @raise = false
      super
    end
  end
end
