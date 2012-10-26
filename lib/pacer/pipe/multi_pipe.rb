module Pacer::Pipes
  class MultiPipe < RubyPipe
    import com.tinkerpop.pipes.util.iterators.MultiIterator
    import com.tinkerpop.pipes.Pipe

    attr_reader :pipes

    def initialize(enums)
      super()
      @pipes = enums.map do |e|
        if e.is_a? Pipe
          e
        else
          e.to_iterable
        end
      end
      setStarts MultiIterator.new(*pipes)
    end

    def +(enum)
      MultiPipe.new(pipes + [enum])
    end

    def -(enum)
      MultiPipe.new(pipes - [enum])
    end

    def getCurrentPath
      starts.getCurrentPath
    end

    def processNextStart
      starts.next
    end

    def inspect
      "#<MultiPipe #{ pipes.count } sources>"
    end
  end
end
