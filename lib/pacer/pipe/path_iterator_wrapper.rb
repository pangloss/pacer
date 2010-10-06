module Pacer::Pipes
  # TODO: move this functionality right into AbstractPipe
  class PathIteratorWrapper
    attr_reader :pipe, :previous, :value

    def initialize(pipe, previous = nil)
      @pipe = pipe
      @previous = previous if previous.class == self.class
    end

    def path
      if @previous
        prev_path = @previous.path
        if prev_path.last == @value
          prev_path
        else
          prev_path + [@value]
        end
      else
        [@value]
      end
    end

    def next
      @value = @pipe.next
    end
  end
end
