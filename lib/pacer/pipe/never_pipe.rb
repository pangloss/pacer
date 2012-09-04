module Pacer::Pipes
  class NeverPipe < RubyPipe
    protected

    def processNextStart
      raise EmptyPipe.instance
    end
  end
end
