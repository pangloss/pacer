module Pacer::Pipes
  class ExpandablePipe < RubyPipe
    def initialize
      super()
      @queue = java.util.LinkedList.new
    end

    def add(element, metadata = nil, path = nil)
      @queue.add [element, metadata, path]
    end

    def metadata
      @metadata
    end

    def next
      super
    ensure
      @path = @next_path
      @metadata = @next_metadata
    end

    protected

    def processNextStart
      if @queue.isEmpty
        @next_metadata = nil
        r = @starts.next
        if pathEnabled and @starts.respond_to? :getCurrentPath
          @next_path = @starts.getCurrentPath
        else
          @next_path = java.util.ArrayList.new
        end
        r
      else
        element, @next_metadata, @next_path = @queue.remove
        element
      end
    end

    def getPathToHere
      path = java.util.ArrayList.new
      if @path
        @path.each do |e|
          path.add e
        end
      end
      path
    end
  end
end
