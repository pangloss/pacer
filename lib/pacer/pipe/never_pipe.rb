module Pacer::Pipes
  class NeverPipe < RubyPipe
    protected

    def processNextStart
      raise NoSuchElementException
    end
  end
end
