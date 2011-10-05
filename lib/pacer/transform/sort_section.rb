module Pacer
  module Routes
    module RouteOperations
      def sort_section(section = nil, &block)
        chain_route transform: :sort_section, block: block, section: section
      end
    end
  end

  module Transform
    module SortSection
      class SortSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :block, :to_sort, :to_emit, :section

        def initialize(section, block)
          super()
          @to_emit = []
          @section = section
          @to_sort = []
          @block = block
          if section
            section.visitor = self
          else
            on_element nil
          end
        end

        def processNextStart
          while to_emit.empty?
            element = @starts.next
            to_sort << element
          end
          element, sort_value = to_emit.shift
          element
        rescue NativeException => e
          if e.cause.getClass == Pacer::NoSuchElementException.getClass
            if to_emit.empty?
              raise e.cause
            else
              after_element
              retry
            end
          else
            raise e
          end
        end

        def on_element(element)
          @section_element = element
        end

        def after_element
          if to_sort.any?
            if block
              sorted = to_sort.sort_by do |element|
                block.call element #, @section_element
              end
              to_emit.concat sorted 
              @to_sort = []
            else
              to_emit.concat to_sort.sort
            end
          end
        end
      end

      attr_accessor :block
      attr_reader :section_name, :section_route

      def section=(section)
        if section.is_a? Symbol
          @section_name = section
          @section_route = @back.get_section_route(section)
        elsif section.is_a? Pacer::Route and section.respond_to? :section_name
          @section_name = section.section_name
          @section_route = section
        else
          raise ArgumentError, "Unknown section #{ section }. Provide either a name or a route created with the #section methed."
        end
      end

      protected

      def attach_pipe(end_pipe)
        pipe = SortSectionPipe.new(@section_route.send(:section_visitor), block)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
