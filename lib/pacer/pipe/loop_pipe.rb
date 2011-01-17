module Pacer::Pipes
  class LoopPipe < RubyPipe

    def initialize(looping_pipe, control_block)
      super()
      @control_block = control_block

      @expando = ExpandablePipe.new
      empty = java.util.ArrayList.new
      @expando.setStarts empty.iterator
      looping_pipe.setStarts(@expando)
      @looping_pipe = looping_pipe
    end

    def enablePath
      @path_enabled = true
      @looping_pipe.enablePath
      super
    end
    alias enable_path enablePath

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
    end

    protected

    def processNextStart
      while true
        # FIXME: hasNext shouldn't be raising an exception...
        has_next = @looping_pipe.hasNext rescue nil
        if has_next
          element = @looping_pipe.next
          depth = (@expando.metadata || 0) + 1
          @next_path = @looping_pipe.path if @path_enabled
        else
          element = @starts.next
          @next_path = @starts.path if @path_enabled
          depth = 0
        end
        case @control_block.call element, depth, @next_path
        when :loop
          @expando.add element, depth, @next_path
        when :emit
          return element
        when :emit_and_loop, :loop_and_emit
          @expando.add element, depth, @next_path
          return element
        when false, nil
        else
          @expando.add element, depth, @next_path
          return element
        end
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
