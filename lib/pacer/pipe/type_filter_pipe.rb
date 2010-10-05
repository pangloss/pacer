module Pacer::Pipe
  class TypeFilterPipe < AbstractPipe
    def initialize(type)
      super()
      @type = type
    end

    def set_starts(starts)
      @starts = starts
      super
    end

    def processNextStart()
      while s = @starts.next
        return s if s.is_a? @type
      end
      raise Pacer::NoSuchElementException.new
    end
  end
end
