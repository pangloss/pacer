module Pacer::Pipes
  class ProcessPipe < AbstractPipe
    field_reader :starts
    attr_reader :is_element, :extensions, :back, :block, :graph

    def initialize(back, block)
      super()
      @block = Pacer::Wrappers::WrappingPipeFunction.new back, block
    end

    def processNextStart
      while true
        obj = starts.next
        block.call(obj)
        return obj
      end
    end
  end
end
