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
    def initialize(queue_length)
      super()
      @queue_length = queue_length
      @rebalancing = []
      @rebal_length = 0
      @silos = [[], [], [], []]
      @clearing = []
      @num_silos = 10
    end

    def setNumSilos(n)
      @num_silos = n
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
          n = @queue_length / @num_silos
          @silos = []
          @num_silos.times do |silo|
            @silos << @rebalancing.slice(silo * n, n).sort
          end
          @rebalancing = []
        else
          @clearing = @rebalancing.sort
          @rebalancing = []
          return processNextStart
        end
      end
      if @starts.hasNext
        if @silos.first.any?
          element = @starts.next
          @silos.each_with_index do |silo, i|
            if element < silo.last
              silo << element
              silo.sort!
              break
            end
          end
          return @silos.first.shift
        else
          @clearing = @silos[1]
          @rebalancing = @silos[2..-1].inject([]) { |all, silo| all + silo }
          @silos = []
          @rebal_length = @rebalancing.length
          return @rebalancing.shift
        end
      else
        @clearing = @silos.inject([]) { |all, silo| all + silo }
        @silos = []
        return processNextStart if @clearing.any?
      end
      raise Pacer::NoSuchElementException.new
    end
  end
end
