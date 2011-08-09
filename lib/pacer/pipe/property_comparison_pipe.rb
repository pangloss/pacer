module Pacer::Pipes
  class PropertyComparisonFilterPipe < RubyPipe
    def initialize(left, right, filter)
      super(filter)
      @left = left.to_s
      @right = right.to_s
    end

    protected

    def processNextStart
      while true
        obj = @starts.next
        unless Pacer::Pipes::PipeHelper.compareObjects(obj.getProperty(@left), obj.getProperty(@right))
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
