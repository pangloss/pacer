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
        attr_reader :block_1, :block_2, :to_sort, :to_emit, :section

        def initialize(section, block)
          super()
          @to_emit = []
          @section = section
          @to_sort = []
          if section
            section.visitor = self
          else
            on_element nil
          end
          if block
            if block.arity == 1
              @block_1 = block
              section.use_on_element = false
            elsif block.arity == 2 or block.arity < 0
              @block_2 = block
            end
          else
            section.use_on_element = false
          end
        end

        def processNextStart
          while to_emit.empty?
            element = @starts.next
            to_sort << element
          end
          to_emit.shift
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
            if block_1
              sorted = to_sort.sort_by do |element|
                block_1.call element
              end
            elsif block_2
              sorted = to_sort.sort_by do |element|
                block_2.call element, @section_element
              end
            else
              sorted = to_sort.sort
            end
            to_emit.concat sorted
            @to_sort = []
          end
        end
      end

      include Pacer::Visitors::VisitsSection

      attr_accessor :block

      protected

      def attach_pipe(end_pipe)
        pipe = SortSectionPipe.new(section_visitor, block)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
