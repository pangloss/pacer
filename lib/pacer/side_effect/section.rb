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
      attr_writer :section_name

      def section_name
        @section_name = "section_#{ object_id }" unless defined? @section_name
        @section_name
      end

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
