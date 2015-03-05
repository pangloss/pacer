module Pacer
  module Routes
    module RouteOperations
      # Set operations on sections like intersect_sections, difference_sections, etc. allow a route to do things like produce a stream of the set of
      # employees who worked in multiple groups within a compnay, in a single traversal. To take that example further, imagine that we define the
      # following traversals:
      #
      # company.groups.employees
      #
      # Give me all of the employees who have worked in every group in the company:
      #
      # company.groups.as(:g).employees.intersect_sections(:g)
      #
      # To understand how this works, we can think about the underlying structure of the graph, with a company with 2 groups which share employee e2
      # and also have their own employees:
      #
      # (c)--->(g1)=--->(e1)
      #   |         '-->(e2)
      #   |             /
      #   |        .---`
      #   '---(g2)=--->(e3)
      #
      # The simple route company.groups.employees.paths will produce:
      #   [c, g1, e1]
      #   [c, g1, e2]
      #   [c, g2, e2]
      #   [c, g2, e3]
      #
      # By adding a section to the groups with groups.as(:section_name), we set up the mechanism allowing us to respond to the event when the group in
      # the path changes in subsequent stages of the route. That is what .intersect_sections(:section_name) does. It can conceptually keep a set of
      # employees from each group and then when the source data has been exhausted, it can do a set intersection on those groups, then use the
      # resulting set as its source of resulting data.
      #
      def intersect_sections(section)
        chain_route transform: Pacer::Transform::IntersectSections, section: section, operation: :intersection
      end

      # See details on intersect_section. Emits only elements that are not in other sections.
      def difference_sections(section)
        chain_route transform: Pacer::Transform::IntersectSections, section: section, operation: :difference
      end

      # See details on intersect_section. Emits only elements that are in the first section and not in any subsequent ones.
      def left_difference_sections(section)
        chain_route transform: Pacer::Transform::IntersectSections, section: section, operation: :left_difference
      end

      # See details on intersect_section. Emits only elements that are in the last section and not in the right difference of the previous section.
      #
      # This one can be confusing if you've got more than 2 sections...
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
