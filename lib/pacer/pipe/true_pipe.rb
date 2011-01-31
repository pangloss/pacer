module Pacer::Pipes
  class TruePipe < RubyPipe
    protected

    def processNextStart
      true
    end
  end

  class FalsePipe < RubyPipe
    protected

    def processNextStart
      false
    end
  end
end
