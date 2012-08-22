module Pacer::Pipes
  class VerticesPipe < AbstractPipe
    attr_reader :starts

    def setStarts(starts)
      @starts = starts.first
      self.iter = @starts.getVertices.iterator
    end

    def processNextStart
      iter.next
    end

    def reset
      self.iter = @starts.getVertices.iterator
    end

    private

    attr_accessor :iter
  end
end
