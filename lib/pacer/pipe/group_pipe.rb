module Pacer::Pipes
  class GroupPipe < RubyPipe
    def initialize(grouped_pipe_start, grouped_pipe, unique = false)
      super()
      @unique = unique
      @grouped_pipe = grouped_pipe
      @expando = ExpandablePipe.new
      @expando.setStarts java.util.ArrayList.new.iterator
      grouped_pipe_start.setStarts(@expando)
      @grouped_pipe_start = grouped_pipe_start
      @next_group = nil
      @groups = {}
    end

    def hasNext
      !!@nextKey or super
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end

    protected

    def processNextStart
      key = @next_key
      values = []
      @next_key = nil
      key ||= @starts.next
      begin
        @expando.add key, java.util.ArrayList.new, nil
        loop_values = []
        begin
          while true
            print '+'
            loop_values << @grouped_pipe.next
          end
        rescue => e
          puts e.message
          values += loop_values
        end
        while true
          k = @starts.next
          if k != key
            @next_key = k
            return [key, values]
          else
            print 'x'
            values += loop_values
          end
        end
      rescue => e
        puts e.message
        [key, values]
      end
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
