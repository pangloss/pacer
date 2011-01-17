module Pacer::Pipes
  class RubyPipe < AbstractPipe
    attr_accessor :starts
    attr_accessor :path_enabled

    def setStarts(starts)
      @starts = starts
    end
    alias set_starts setStarts

    def enablePath
      super()
      self.path_enabled = true
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

    # raises the java exception I need. When raised in the normal way,
    # Java doesn't seem to catch it correctly.
    def pipe_empty!
      java.util.ArrayList.new.iterator.next
    end
  end
end
