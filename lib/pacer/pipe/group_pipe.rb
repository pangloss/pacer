module Pacer::Pipes
  class GroupPipe < RubyPipe
    def initialize
      super()
      @next_key = nil
      @key_pipes = []
      @values_pipes = []
      @current_keys = []
      @current_values = nil
    end

    def setUnique(bool)
      @unique = unique
      @groups = {}
    end

    def addKeyPipe(from_pipe, to_pipe)
      @key_pipes << prepare_aggregate_pipe(from_pipe, to_pipe)
    end

    def addValuesPipe(from_pipe, to_pipe)
      @values_pipes << prepare_aggregate_pipe(from_pipe, to_pipe)
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

    def prepare_aggregate_pipe(from_pipe, to_pipe)
      expando = ExpandablePipe.new
      expando.setStarts java.util.ArrayList.new.iterator
      from_pipe.setStarts(expando)
      agg_pipe = com.tinkerpop.pipes.sideeffect.AggregatorPipe.new
      cap_pipe = com.tinkerpop.pipes.sideeffect.SideEffectCapPipe.new agg_pipe
      agg_pipe.setStarts to_pipe
      cap_pipe.setStarts to_pipe
      [expando, cap_pipe]
    end

    def processNextStart
      while true
        if @current_keys.empty?
          element = next_element
          @current_keys = get_keys(element)
          @current_values = get_values(element) if @current_keys.any?
        else
          return [@current_keys.removeFirst, @current_values]
        end
      end
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end

    def get_keys(element)
      array = java.util.LinkedList.new
      @key_pipes.each do |expando, to_pipe|
        array.addAll next_results(expando, to_pipe, element)
      end
      array
    end

    def get_values(element)
      @values_pipes.map do |expando, to_pipe|
        next_results(expando, to_pipe, element)
      end
    end

    def next_results(expando, pipe, element)
      expando.add element, java.util.ArrayList.new, nil
      pipe.reset
      pipe.next
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
