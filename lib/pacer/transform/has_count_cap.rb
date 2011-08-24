module Pacer
  module Routes
    module RouteOperations
      def has_count_route(opts = {})
        chain_route({ :transform => :has_count_cap }.merge(opts))
      end

      def has_count?(opts = {})
        has_count_route(opts).first
      end
    end
  end

  module Transform
    module HasCountCap
      import com.tinkerpop.pipes.transform.HasCountPipe

      attr_accessor :min, :max

      protected

      def attach_pipe(end_pipe)
        pipe = HasCountPipe.new(min || -1, max || -1)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
