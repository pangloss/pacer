module Pacer::Pipes
  class LabelPrefixPipe < RubyPipe
    def initialize(prefix)
      super()
      @prefix = /^#{prefix}/
    end

    def processNextStart
      while true
        edge = @starts.next
        return edge if edge.label =~ @prefix
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
