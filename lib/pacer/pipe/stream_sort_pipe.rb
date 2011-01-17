module Pacer::Pipes
  # has 3 states:
  # - starts in rebalancing mode to build up a working set which stores
  #   elements in 4 silos
  # - if the first silo becomes empty, it goes into clearing mode
  # - in clearing mode, it will empty all elements out of the first non-empty silo
  # - it then goes back into rebalancing mode
  #
  # Number of silos is 4 by default, a number I pulled out of my ass without any testing.
  class StreamSortPipe < RubyPipe
    def initialize(queue_length = 100, silo_size = 10)
      super()
      @queue_length = queue_length
      @rebalancing = []
      @rebal_length = 0
      @first_silo = []
      @second_silo = []
      @third_silo = []
      @clearing = []
      @silo_size = 3
    end

    def setSiloSize(n)
      @silo_size = n
    end

    def processNextStart
      if @clearing.any?
        return @clearing.shift
      end
      while @rebal_length < @queue_length and @starts.hasNext
        @rebalancing << @starts.next
        @rebal_length += 1
      end
      if @rebalancing.any?
        if @starts.hasNext
          @rebalancing.sort!
          @first_silo = @rebalancing.slice(0, @silo_size)
          @second_silo = @rebalancing.slice(@silo_size, @silo_size * 2) || []
          @third_silo = @rebalancing.slice(@silo_size * 2..-1) || []
          @rebalancing = []
        else
          @clearing = @rebalancing.sort
          @rebalancing = []
          return processNextStart
        end
      end
      if @starts.hasNext
        if @first_silo.any?
          element = @starts.next
          begin
            if @element < @first_silo.last
              @first_silo << element
              @first_silo.sort!
            elsif @second_silo.none? or @element < @second_silo.last
              @second_silo.unshift element
            else
              @third_silo << element
            end
          rescue
            @first_silo.unshift @element
          end
          return @first_silo.shift
        else
          @clearing = @second_silo
          @clearing.sort!
          @rebalancing = @third_silo
          @rebal_length = @rebalancing.length
          return @rebalancing.shift
        end
      else
        @clearing = @first_silo + @second_silo.sort! + @third_silo.sort!
        return processNextStart if @clearing.any?
      end
      raise Pacer::NoSuchElementException
    rescue NativeException => e
      if e.cause.getClass == NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
