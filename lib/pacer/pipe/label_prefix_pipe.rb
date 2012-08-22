module Pacer::Pipes
  class LabelPrefixPipe < RubyPipe
    def initialize(prefix)
      super()
      @prefix = /^#{prefix}/
    end

    def processNextStart
      while true
        edge = @starts.next
        return edge if edge.label =~ @prefix
      end
    end
  end
end
