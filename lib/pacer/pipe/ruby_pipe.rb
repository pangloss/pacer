module Pacer::Pipes
  class RubyPipe < AbstractPipe
    attr_reader :starts

    def setStarts(starts)
      @starts = starts
    end
    alias set_starts setStarts

    def reset
      super
      @starts.reset if starts.respond_to? :reset
    end

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
