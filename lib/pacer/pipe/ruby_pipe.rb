module Pacer::Pipes
  class RubyPipe < AbstractPipe
    attr_accessor :starts

    def setStarts(starts)
      @starts = starts
    end
    alias set_starts setStarts

    def enablePath
      super()
      starts.enablePath if starts.respond_to? :enablePath
    end
    alias enable_path enablePath

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
