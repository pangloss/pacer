module Pacer::Pipes
  class LabelCollectionFilterPipe < RubyPipe
    def initialize(labels)
      super()
      @labels = Set[*labels.map(&:to_s)]
    end

    def processNextStart
      while true
        edge = @starts.next
        return edge if edge and @labels.include? edge.getLabel
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
