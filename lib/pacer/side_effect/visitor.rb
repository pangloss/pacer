module Pacer
  module Routes
    module RouteOperations
      def visitor(visitor)
        chain_route side_effect: :visitor, visitor: visitor
      end
    end
  end

  module SideEffect
    module Visitor
      attr_reader :visitor

      def visitor=(v)
        @visitor = v
        @visitor = @visitor.on_route(self) if @visitor.respond_to? :on_route
      end

      def element_type
        if @visitor.respond_to? :element_type
          @visitor.element_type
        else
          super
        end
      end

      protected

      def attach_pipe(end_pipe)
        pipe = @visitor.attach_pipe(end_pipe) if @visitor.respond_to? :attach_pipe
        pipe ||= Pacer::Pipes::VisitorPipe.new(visitor)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
