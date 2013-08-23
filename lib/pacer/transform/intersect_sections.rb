module Pacer
  module Routes
    module RouteOperations
      def intersect_sections(section)
        chain_route transform: Pacer::Transform::IntersectSections, section: section, operation: :intersection
      end

      def difference_sections(section)
        chain_route transform: Pacer::Transform::IntersectSections, section: section, operation: :difference
      end

      def left_difference_sections(section)
        chain_route transform: Pacer::Transform::IntersectSections, section: section, operation: :left_difference
      end

      def right_difference_sections(section)
        chain_route transform: Pacer::Transform::IntersectSections, section: section, operation: :right_difference
      end
    end
  end


  module Transform
    module IntersectSections
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      attr_accessor :operation

      protected

      def attach_pipe(end_pipe)
        pipe = IntersectSectionPipe.new(section_visitor, operation)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class IntersectSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :section, :reduce_block
        attr_accessor :to_emit, :current_set, :all_sets

        def initialize(section, operation)
          super()
          @section = section
          case operation
          when :difference
            @reduce_block = proc { |a, b| (a - b) + (b - a) }
          when :left_difference
            @reduce_block = proc { |a, b| a - b }
          when :right_difference
            @reduce_block = proc { |a, b| b - a }
          when :intersection
            @reduce_block = proc { |a, b| a.intersection b }
          end
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
            self.to_emit = all_sets.reduce(&reduce_block).to_a
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
