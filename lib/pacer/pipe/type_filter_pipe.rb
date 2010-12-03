module Pacer::Pipes
  class TypeFilterPipe < RubyPipe
    def initialize(type)
      super()
      @type = type
    end

    def processNextStart()
      while @starts.hasNext
        s = @starts.next
        return s if s.is_a? @type
      end
      raise Pacer::NoSuchElementException.new
    end
  end
end
