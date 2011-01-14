module Pacer::Pipes
  class LoopPipe < RubyPipe

    def initialize(looping_pipe, &control_block)
      @control_block = control_block

      empty = java.util.ArrayList.new
      @expando = ExpandableIterator.new empty.iterator
      looping_pipe.setStarts(@expando)
      @looping_pipe = looping_pipe

      @history = {}
    end

    protected

    def processNextStart
      while true
        if @looping_pipe.hasNext
          element = @looping_pipe.next
          @history[element] = @looping_pipe.getPath if @path_enabled
        else
          element = @starts.next
          @history[element] = nil if @path_enabled
        end
        @element = element
        if @control_block.call element
          @expando.add element
        else
          return element
        end
      end
    end

    def getPathToHere
      path = unravel_history @element
      if @starts.respond_to? :getPath
        @starts.getPath + path
      else
        path
      end
    end

    def unravel_history(element)
      if path = @history[element]
        e = path.first
        if e == element
          path
        else
          paths = unravel_history(e)
          paths + path
        end
      else
        []
      end
    end
  end
end
