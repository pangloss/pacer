module Pacer::Pipes
  class IsUniquePipe < RubyPipe
    import java.util.ArrayList
    import com.tinkerpop.pipes.sideeffect.SideEffectPipe
    import com.tinkerpop.pipes.util.ExpandableIterator
    import com.tinkerpop.pipes.filter.DuplicateFilterPipe

    include SideEffectPipe

    def initialize
      super()
      prepare_state
    end

    def processNextStart
      value = starts.next
      check_uniqueness value if @unique
      value
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end

    def reset
      super()
      prepare_state
    end

    def unique?
      @unique
    end

    def getSideEffect
      @unique
    end

    protected

    def check_uniqueness(value)
      @expando.add value
      @unique_pipe.next
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        @unique = false
      else
        raise e
      end
    end

    def prepare_state
      @unique = true
      @expando = ExpandableIterator.new ArrayList.new.iterator
      @unique_pipe = DuplicateFilterPipe.new
      @unique_pipe.setStarts @expando
    end

  end
end
