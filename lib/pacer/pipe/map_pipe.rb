module Pacer::Pipes
  class MapPipe < AbstractPipe
    field_reader :starts

    attr_reader :block

    def initialize(back, block)
      super()
      @block = Pacer::Wrappers::WrappingPipeFunction.new back, block
      @block = Pacer::Wrappers::UnwrappingPipeFunction.new @block
    end

    def processNextStart
      while true
        obj = starts.next
        return block.call(obj)
      end
    end
  end
end
