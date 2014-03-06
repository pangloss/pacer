module Pacer::Pipes
  class EdgesPipe < AbstractPipe
    attr_reader :starts

    def setStarts(starts)
      @starts = starts.first
      self.iter = @starts.getEdges.iterator
    end

    def processNextStart
      iter.next
    end

    def reset
      self.iter = @starts.getEdges.iterator
    end

    private

    attr_accessor :iter
  end
end
