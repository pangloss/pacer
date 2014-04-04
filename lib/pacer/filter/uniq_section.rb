module Pacer
  module Routes
    module RouteOperations
      def uniq_in_section(section = nil)
        chain_route filter: Pacer::Filter::UniqueSectionFilter, section: section
      end
    end
  end

  module Filter
    module UniqueSectionFilter
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      def attach_pipe(end_pipe)
        pipe = UniqueSectionPipe.new(self, section_visitor)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class UniqueSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :seen, :section, :route


        def initialize(route, section)
          super()
          @seen = Set[]
          @section = section
          @route = route
          section.visitor = self if section
        end

        def processNextStart
          while true
            element = starts.next
            unless seen.include? element
              seen << element
              return element
            end
          end
        end

        def after_element
          seen.clear
        end

        def reset
          seen.clear
        end
      end
    end
  end
end

