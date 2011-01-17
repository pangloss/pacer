module Pacer::Pipes
  class TypeFilterPipe < RubyPipe
    def initialize(type)
      super()
      @type = type
    end

    def processNextStart()
      while @starts.hasNext
        s = @starts.next
        return s if s.is_a? @type
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
