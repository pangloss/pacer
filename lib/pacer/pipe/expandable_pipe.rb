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
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    ensure
      @path = @next_path
      @metadata = @next_metadata
    end

    protected

    def processNextStart
      if @queue.isEmpty
        @next_metadata = nil
        r = @starts.next
        if @starts.respond_to? :getPath
          @next_path = @starts.getPath
        else
          @next_path = java.util.ArrayList.new
        end
        r
      else
        element, @next_metadata, @next_path = @queue.remove
        element
      end
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
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
