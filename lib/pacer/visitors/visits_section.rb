module Pacer
  module Visitors
    # This module is mixed in to the route that actually refers to this section.
    module VisitsSection
      attr_reader :section, :section_route

      def section=(section)
        if section.is_a? Symbol
          @section = section
          @section_route = @back.get_section_route(section)
        elsif section.is_a? Pacer::Route and section.respond_to? :section_name
          @section = section.section_name
          @section_route = section
        else
          raise ArgumentError, "Unknown section #{ section }. Provide either a name or a route created with the #section methed."
        end
        @section_route.will_visit!
        @section_route
      end

      protected

      def section_visitor
        section_route.section_visitor if section_route
      end

      def section_visitor_target
        section_route.visitor_target if section_route
      end
    end
  end
end
