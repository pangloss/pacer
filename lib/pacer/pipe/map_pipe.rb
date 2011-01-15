module Pacer::Pipes
  class MapPipe < RubyPipe
    def initialize(block)
      super()
      @block = block
    end

    def processNextStart
      while true
        obj = @starts.next
        return @block.call(obj)
      end
    end
  end
end
