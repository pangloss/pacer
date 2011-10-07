module Pacer::Pipes
  class LoopPipe < RubyPipe
    import java.util.ArrayList

    def initialize(graph, looping_pipe, control_block)
      super()
      @control_block = control_block

      @expando = ExpandablePipe.new
      empty = ArrayList.new
      @expando.setStarts empty.iterator
      looping_pipe.setStarts(@expando)
      @looping_pipe = looping_pipe
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
    end

    def setStarts(starts)
      @starts_has_path = starts.respond_to? :getPath
      super
    end

    protected

    def processNextStart
      while true
        # FIXME: hasNext shouldn't be raising an exception...
        has_next = @looping_pipe.hasNext rescue nil
        if has_next
          element = @looping_pipe.next
          depth = (@expando.metadata || 0) + 1
          @next_path = @looping_pipe.getPath
        else
          element = @starts.next
          if @starts_has_path
            @next_path = @starts.getPath
          else
            @next_path = ArrayList.new
            @next_path.add element
          end
          depth = 0
        end
        element.graph ||= @graph if element.respond_to? :graph=
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
      path = ArrayList.new
      if @path
        @path.each do |e|
          path.add e
        end
      end
      path
    end
  end
end
