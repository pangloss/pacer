module Pacer
  module Routes
    module RouteOperations
      def intersect_sections(section = nil)
        chain_route transform: Pacer::Transform::IntersectSections, section: section
      end
    end
  end


  module Transform
    module IntersectSections
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      protected

      def attach_pipe(end_pipe)
        pipe = IntersectSectionPipe.new(section_visitor)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class IntersectSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :section
        attr_accessor :to_emit, :current_set, :all_sets

        def initialize(section)
          super()
          @section = section
          self.all_sets = []
          if section
            section.visitor = self
          else
            on_element nil
          end
        end

        def processNextStart
          unless to_emit
            while starts.hasNext
              current_set << starts.next
            end
            self.to_emit = all_sets.reduce { |a, b| a.intersection b }.to_a
          end
          raise EmptyPipe.instance if to_emit.empty?
          to_emit.shift
        end

        def on_element(x)
          self.current_set = Set[]
          all_sets << current_set
        end
      end
    end
  end
end
