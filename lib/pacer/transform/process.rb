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

      def help(section = nil)
        case section
        when nil
          puts <<HELP
The process method executes the given block for each element that is
passed through the route. After the block is called, the element that
was passed to it is emitted to be handled by the next step in the route.

It is Pacer's lazy version of the #each method.

HELP
        else
          super
        end
      end
      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::ProcessPipe.new(back, block)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
