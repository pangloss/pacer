module Pacer::Pipes
  class PropertyComparisonFilterPipe < RubyComparisonFilterPipe
    def initialize(left, right, filter)
      super(filter)
      @left = left.to_s
      @right = right.to_s
    end

    protected

    def processNextStarts
      while true
        obj = @starts.next
        # FIXME: is this consistent with the way other pipes work?
        #        I think they usually work like reject, but this is like select...
        if compareObjects(obj.getProperty(@left), obj.getProperty(@right))
          return obj
        end
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
