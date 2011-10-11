module Pacer
  module Routes
    module RouteOperations
      def process(opts = {}, &block)
        chain_route({:transform => :process, :block => block}.merge(opts))
      end
    end
  end

  module Transform
    module Process
      attr_accessor :block

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::ProcessPipe.new(back, block)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
