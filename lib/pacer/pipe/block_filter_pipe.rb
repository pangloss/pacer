module Pacer::Pipes
  class BlockFilterPipe < RubyPipe
    def initialize(starts, back, block)
      super()
      set_starts(starts)
      @back = back
      @block = block

      @extensions = @back.extensions + [Pacer::Extensions::BlockFilterElement]
    end

    def processNextStart()
      while raw_element = @starts.next
        extended_element = raw_element.add_extensions(@extensions)
        extended_element.back = @back
        ok = @block.call extended_element
        return raw_element if ok
      end
      raise Pacer::NoSuchElementException.new
    end
  end
end
