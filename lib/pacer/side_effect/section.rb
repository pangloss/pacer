module Pacer
  module Routes
    module RouteOperations
      def section(section_name = nil)
        chain_route side_effect: :section, section_name: section_name
      end
    end
  end

  module SideEffect
    module Section
      attr_accessor :section_name

      protected

      attr_reader :section_visitor

      def attach_pipe(end_pipe)
        @section_visitor = pipe = Pacer::Pipes::SimpleVisitorPipe.new
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
