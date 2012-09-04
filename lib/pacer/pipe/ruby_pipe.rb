module Pacer::Pipes
  class RubyPipe < AbstractPipe
    field_reader :pathEnabled

    attr_reader :starts

    def setStarts(starts)
      @starts = starts
    end
    alias set_starts setStarts

    def reset
      super
      starts.reset if starts.respond_to? :reset
    end

    def enablePath(b)
      super
      starts.enablePath b if starts.respond_to? :enablePath
    end

    protected

    def getPathToHere
      if starts.respond_to? :getCurrentPath
        starts.getCurrentPath
      else
        java.util.ArrayList.new
      end
    end
  end
end
