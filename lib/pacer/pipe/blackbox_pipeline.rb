module Pacer::Pipes
  # Same concept as the regular pipeline, but this one
  # does not touch the intermediate pipes. They must be
  # wired together before being passed in to this object.
  # This allows me to build a pipeline in Pacer and then
  # pass it on to a pipe like FutureFilterPipe that only
  # knows how to act on a single pipe.
  class BlackboxPipeline
    include com.tinkerpop.pipes.Pipe 
    
    def initialize(start_pipe, end_pipe)
      @start_pipe = start_pipe
      @end_pipe = end_pipe
    end

    def setStarts(pipe)
      if pipe.respond_to? :iterator
        @start_pipe.setStarts pipe.iterator
      else
        @start_pipe.setStarts pipe
      end
    end

    def next
      @end_pipe.next
    end

    def hasNext
      @end_pipe.hasNext
    end

    def reset
      @end_pipe.reset
    end

    def getPath
      @end_pipe.getPath
    end

    def iterator
      @end_pipe.iterator
    end

    def to_s
      "[#{ @start_pipe }...#{ @end_pipe }]"
    end
  end
end
