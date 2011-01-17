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

      def to_h
        each { }
        h = {}
        side_effect.each do |k,v|
          h[k] = v
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
        @pipe.set_starts(end_pipe)
        @pipe
      end
    end
  end
end
