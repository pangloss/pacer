module Pacer
  module Routes::RouteOperations
    def fast_group_count(hash_map = nil)
      chain_route :side_effect => :group_count, :hash_map => hash_map
    end
  end

  module SideEffect
    module GroupCount
      def hash_map=(hash_map)
        @hash_map = hash_map
      end

      def at_least(n)
        @min = n
        self
      end

      def to_h
        c = 0
        each { c = c + 1 }
        puts c
        h = {}
        min = @min || 0
        side_effect.each do |k,v|
          h[k] = v if v >= min
        end
        h
      end

      protected

      def attach_pipe(end_pipe)
        if @hash_map
          @pipe = com.tinkerpop.pipes.sideeffect.GroupCountPipe.new @hash_map
        else
          @pipe = com.tinkerpop.pipes.sideeffect.GroupCountPipe.new
        end
        @pipe.set_starts(end_pipe) if end_pipe
        @pipe
      end
    end
  end
end
