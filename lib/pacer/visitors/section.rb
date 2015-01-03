module Pacer
  module Routes
    module RouteOperations
      def section(section_name = nil, visitor_target = nil)
        chain_route visitor: :section, section_name: section_name, visitor_target: visitor_target
      end

      # see #as_var for the old as implementation
      def as(section_name = nil)
        section section_name
      end
    end
  end

  module Visitors
    module Section
      attr_accessor :section_name, :visitor_target

      def will_visit!
        @visitor_count = visitor_count + 1
        visitor_count - 1
      end

      def section_visitor!(visitor_num)
        vpipes = Thread.current["visitors_#{object_id}"]
        vpipe = vpipes[visitor_num]
        vpipes[visitor_num] = nil
        vpipe
      end

      protected

      def visitor_count
        @visitor_count = 0 unless defined? @visitor_count
        @visitor_count
      end

      attr_reader :section_visitors

      def attach_pipe(end_pipe)
        # With detached pipes, pipe construction happens in
        # multiple threads, multiple times.
        pipe = end_pipe
        vpipes = (1..visitor_count).map do
          pipe = Pacer::Pipes::SimpleVisitorPipe.new Pacer::Wrappers::WrapperSelector.build(graph, element_type, extensions), graph
          pipe.setStarts end_pipe if end_pipe
          end_pipe = pipe
        end
        Thread.current["visitors_#{object_id}"] = vpipes
        pipe
      end

      def inspect_class_name
        "#{super}(#{section_name.inspect})"
      end
    end
  end
end
