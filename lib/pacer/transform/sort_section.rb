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
        attr_reader :getPathToHere

        def initialize(route, section, block)
          super()
          @to_emit = []
          @section = section
          @to_sort = []
          @paths = []
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
          if pathEnabled
            while to_emit.empty?
              to_sort << [starts.next, starts.getCurrentPath]
            end
          else
            while to_emit.empty?
              to_sort << [starts.next, nil]
            end
          end
          element, @getPathToHere = to_emit.shift
          element
        rescue EmptyPipe, java.util.NoSuchElementException
          if to_emit.empty?
            raise EmptyPipe.instance
          else
            after_element
            retry
          end
        end

        def on_element(element)
          puts "on element with #{ element.class }"
          @section_element = element
        end

        def after_element
          if to_sort.any?
            if block_1
              sorted = to_sort.sort_by do |element, path|
                block_1.call element
              end
            elsif block_2
              sorted = to_sort.sort_by do |element, path|
                block_2.call_with_args element, @section_element, path
              end
            else
              sorted = to_sort.sort_by do |element, path|
                element
              end
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
        pf = Pacer::Wrappers::WrappingPipeFunction.new self, block
        pipe = SortSectionPipe.new(self, section_visitor, pf)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
