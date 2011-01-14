module Pacer
  module Routes
    module RouteOperations
      public

      def loop(&block)
        chain_route :looping_route => block
      end
    end
  end

  module Filter
    module LoopFilter
      def self.triggers
        [:looping_route]
      end

      attr_reader :looping_route

      def looping_route=(route)
        if route.is_a? Proc
          empty = Pacer::Route.new :filter => :empty, :back => self
          @looping_route = route.call(empty)
        else
          @looping_route = route
        end
      end

      def while(yield_paths = false, &block)
        @yield_paths = yield_paths
        @control_block = block
        self
      end

      protected

      def iterator
        iter = super
        iter.enable_path if @yield_paths
        iter
      end

      def attach_pipe(end_pipe)
        unless @control_block
          raise 'No loop control block specified. Use either #while or #until after #loop.'
        end
        pipe = Pacer::Pipes::LoopPipe.new(looping_pipe, @control_block)
        pipe.setStarts(end_pipe)
        pipe
      end

      def looping_pipe
        s, e = looping_route.send(:build_pipeline)
        if s.equal?(e)
          s
        else
          Pacer::Pipes::Pipeline.new s, e
        end
      end
    end
  end
end
