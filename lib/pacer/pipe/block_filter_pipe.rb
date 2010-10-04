module Pacer
  class BlockFilterPipe < AbstractPipe
    attr_accessor :starts

    def initialize(starts, back, block)
      super()
      @starts = starts
      @back = back
      @block = block
      @count = 0
    end

    def processNextStart()
      while s = @starts.next
        path = @back.class.new(s)
        path.send(:back=, @back)
        path.pipe_class = nil
        @count += 1
        path.info = "temp #{ @count }"
        path.extend SingleRoute
        ok = @block.call path
        return s if ok
      end
      raise NoSuchElementException.new
    end
  end
end
