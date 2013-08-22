module Pacer
  module Routes
    module RouteOperations
      def limit_section(section = nil, max)
        chain_route filter: Pacer::Filter::LimitSectionFilter, section_max: max, section: section
      end
    end
  end

  module Filter
    module LimitSectionFilter
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      attr_accessor :section_max

      def attach_pipe(end_pipe)
        pipe = LimitSectionPipe.new(self, section_visitor, section_max)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class LimitSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :max, :section, :route
        attr_accessor :hits


        def initialize(route, section, max)
          super()
          @hits = 0
          @max = max
          @section = section
          @route = route
          section.visitor = self if section
        end

        def processNextStart
          while hits == max
            starts.next
          end
          self.hits += 1
          starts.next
        end

        def after_element
          self.hits = 0
        end

        def reset
          self.hits = 0
        end
      end
    end
  end
end
