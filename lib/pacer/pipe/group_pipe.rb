module Pacer::Pipes
  class GroupPipe < RubyPipe
    def initialize
      super()
      @next_key = nil
    end

    def setUnique(bool)
      @unique = unique
      @groups = {}
    end

    def setKeyPipe(from_pipe, to_pipe)
      @from_key_expando = ExpandablePipe.new
      @from_key_expando.setStarts java.util.ArrayList.new.iterator
      from_pipe.setStarts(@from_key_expando)
      @to_key_pipe = to_pipe
    end

    def setValuesPipe(from_pipe, to_pipe)
      @from_values_expando = ExpandablePipe.new
      @from_values_expando.setStarts java.util.ArrayList.new.iterator
      from_pipe.setStarts(@from_values_expando)
      @to_values_pipe = to_pipe
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
      while true
        element = next_element
        return [get_keys(element), get_values(element)]
      end
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end

    def get_keys(element)
      next_results(@from_key_expando, @to_key_pipe, element)
    end

    def get_values(element)
      next_results(@from_values_expando, @to_values_pipe, element)
    end

    def next_results(expando, pipe, element)
      expando.add element, java.util.ArrayList.new, nil
      pipe.reset
      results = []
      begin
        while pipe.hasNext
          results << pipe.next
        end
      rescue java.util.NoSuchElementException, NoSuchElementException
      rescue Exception => e
        puts e.message
        pp e.backtrace
      end
      results
    end

    def next_element
      if @next_element
        element = @next_element
        @next_element = nil
        element
      else
        @starts.next
      end
    end
  end
end
