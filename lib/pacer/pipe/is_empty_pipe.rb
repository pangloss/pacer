module Pacer::Pipes
  class IsEmptyPipe < RubyPipe
    def initialize
      super
      @raise = false
    end

    def processNextStart
      raise EmptyPipe.instance if @raise
      starts.next
      @raise = true
    rescue EmptyPipe
      true
    else
      raise EmptyPipe.instance
    end

    def reset
      @raise = false
      super()
    end
  end
end
