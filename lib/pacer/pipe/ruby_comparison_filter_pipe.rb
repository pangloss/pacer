module Pacer::Pipes
  class RubyComparisonFilterPipe < AbstractComparisonFilterPipe
    attr_accessor :starts

    def setStarts(starts)
      @starts = starts
    end
    alias set_starts setStarts

    protected

    def getPathToHere
      if starts.respond_to? :path
        starts.path
      else
        java.util.ArrayList.new
      end
    end
  end
end
