module Pacer::Pipes
  class EnumerablePipe < RubyPipe
    def initialize(enumerable)
      super()
      case enumerable
      when Enumerator
        starts = enumerable
      when Pacer::Wrappers::ElementWrapper
        starts = [enumerable.element].to_enum
      when Enumerable
        starts = enumerable.to_enum
      else
        starts = [enumerable].to_enum
      end
      set_starts starts
    end

    def processNextStart()
      @starts.next
    rescue StopIteration
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
