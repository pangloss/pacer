module Pacer::Pipes

  # This exists because the Blueprints GraphVerticesPipe includes the graph itself in the path
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
