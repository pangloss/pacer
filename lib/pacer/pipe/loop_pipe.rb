module Pacer::Pipes
  class LoopPipe < RubyPipe
    import java.util.ArrayList
    BlueprintsGraph = com.tinkerpop.blueprints.Graph

    def initialize(graph, looping_pipe, control_block)
      super()
      @graph = graph
      @control_block = control_block
      @wrapper = Pacer::Wrappers::WrapperSelector.build graph

      @expando = ExpandablePipe.new
      looping_pipe.setStarts(@expando)
      if control_block.arity < 0 or control_block.arity > 2
        @yield_paths = true
        looping_pipe.enablePath true
      end
      @looping_pipe = looping_pipe
    end

    def next
      super
    ensure
      @path = next_path
    end

    def setStarts(starts)
      super
      enablePath true if yield_paths
    end

    def enablePath(b)
      super
      looping_pipe.enablePath true if b and not yield_paths
    end

    protected

    attr_reader :wrapper, :control_block, :expando, :looping_pipe, :graph, :yield_paths
    attr_accessor :next_path

    def processNextStart
      while true
        has_next = looping_pipe.hasNext
        if has_next
          element = looping_pipe.next
          depth = (expando.metadata || 0) + 1
          self.next_path = looping_pipe.getCurrentPath if pathEnabled
        else
          element = starts.next
          self.next_path = starts.getCurrentPath if pathEnabled
          depth = 0
        end
        wrapped = wrapper.new(graph, element)
        if pathEnabled
          path = next_path.map do |e|
            wrapper.new graph, e
          end
          control = control_block.call wrapped, depth, path
        else
          control = control_block.call wrapped, depth
        end
        case control
        when :loop
          expando.add element, depth, next_path
        when :emit
          return element
        when :emit_and_loop, :loop_and_emit
          expando.add element, depth, next_path
          return element
        when false, nil, :discard
        else
          expando.add element, depth, next_path
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
