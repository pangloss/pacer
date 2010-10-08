module Pacer::Pipes
  class BlockFilterPipe < AbstractPipe
    attr_accessor :starts

    def initialize(starts, back, block)
      super()
      @starts = starts
      @back = back
      @block = block
    end

    def processNextStart()
      while s = @starts.next
        s.extend Pacer::Routes::SingleRoute
        s.back = @back
        ok = @block.call s
        return s if ok
      end
      raise Pacer::NoSuchElementException.new
    end
  end
end
