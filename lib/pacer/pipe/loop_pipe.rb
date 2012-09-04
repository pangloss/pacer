module Pacer::Pipes
  class LoopPipe < RubyPipe
    import java.util.ArrayList

    def initialize(graph, looping_pipe, control_block)
      super()
      @graph = graph
      @control_block = control_block
      @wrapper = Pacer::Wrappers::WrapperSelector.build

      @expando = ExpandablePipe.new
      empty = ArrayList.new
      @expando.setStarts empty.iterator
      looping_pipe.setStarts(@expando)
      #if control_block.arity < 0 and 1 < control_block.arity
        @yield_paths = true
        looping_pipe.enablePath true
      #end
      @looping_pipe = looping_pipe
    end

    def next
      super
    ensure
      @path = @next_path
    end

    def setStarts(starts)
      super
      enablePath true if yield_paths
    end

    protected

    attr_reader :wrapper, :control_block, :expando, :looping_pipe, :graph, :yield_paths

    def processNextStart
      while true
        # FIXME: hasNext shouldn't be raising an exception...
        has_next = looping_pipe.hasNext
        if has_next
          element = looping_pipe.next
          depth = (expando.metadata || 0) + 1
          @next_path = looping_pipe.getCurrentPath if yield_paths
        else
          element = starts.next
          if pathEnabled
            @next_path = starts.getCurrentPath
          else
            @next_path = ArrayList.new
            @next_path.add element
          end
          depth = 0
        end
        wrapped = wrapper.new(element)
        wrapped.graph = graph if wrapped.respond_to? :graph=
        path = @next_path.map do |e|
          w = wrapper.new e
          w.graph = graph if w.respond_to? :graph=
          w
        end
        case control_block.call wrapped, depth, path
        when :loop
          expando.add element, depth, @next_path
        when :emit
          return element
        when :emit_and_loop, :loop_and_emit
          expando.add element, depth, @next_path
          return element
        when false, nil
        else
          expando.add element, depth, @next_path
          return element
        end
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
