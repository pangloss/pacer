module Pacer
  module Routes
    module RouteOperations
      def is(value)
        if value.is_a? Symbol
          chain_route filter: Pacer::Filter::SectionFilter, section: value
        else
          chain_route filter: Pacer::Filter::ObjectFilter, value: value
        end
      end

      def is_not(value)
        if value.is_a? Symbol
          chain_route filter: Pacer::Filter::SectionFilter, section: value, negate: true
        else
          chain_route filter: Pacer::Filter::ObjectFilter, value: value, negate: true
        end
      end

      def compact
        is_not nil
      end
    end
  end

  module Filter
    module ObjectFilter
      import com.tinkerpop.pipes.filter.ObjectFilterPipe

      attr_accessor :value, :negate

      protected

      def attach_pipe(end_pipe)
        obj  = if value.respond_to?(:element) then value.element else value end
        pipe = ObjectFilterPipe.new(obj, negate ? Pacer::Pipes::NOT_EQUAL : Pacer::Pipes::EQUAL)
        pipe.set_starts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        if negate
          "is_not(#{ value.inspect })"
        else
          "is(#{ value.inspect })"
        end
      end
    end

    module SectionFilter
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      attr_accessor :negate

      def attach_pipe(end_pipe)
        pipe = FilterSectionPipe.new(section_visitor, negate)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def inspect_class_name
        if negate
          "is_not(#{section.inspect})"
        else
          "is(#{section.inspect})"
        end
      end


      class FilterSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :section, :negate
        attr_accessor :other

        def initialize(section, negate)
          super()
          @section = section
          @negate = negate
          section.visitor = self if section
        end

        def processNextStart
          value = starts.next
          if negate
            while value == other
              value = starts.next
            end
          else
            while value != other
              value = starts.next
            end
          end
          value
        end

        def on_raw_element(x)
          self.other = x
        end

        def reset
          self.other = nil
          super
        end
      end
    end
  end
end
