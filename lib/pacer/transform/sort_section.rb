module Pacer
  module Routes
    module RouteOperations
      def sort_section(section = nil, &block)
        chain_route transform: :sort_section, sort_by_block: block, section: section
      end

      def custom_sort_section(section = nil, &block)
        chain_route transform: :sort_section, custom_sort_block: block, section: section
      end
    end
  end


  module Transform
    module SortSection
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      attr_accessor :sort_by_block
      attr_accessor :custom_sort_block

      protected

      def attach_pipe(end_pipe)
        if custom_sort_block
          wrapper = Pacer::Wrappers::WrapperSelector.build graph, element_type, extensions
          pipe = CustomSortPipe.new(self, section_visitor, custom_sort_block, graph, wrapper)
        else # sort_by_block
          pf = Pacer::Wrappers::WrappingPipeFunction.new self, sort_by_block if sort_by_block
          pipe = SortBySectionPipe.new(self, section_visitor, pf)
        end
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class SortBySectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :pf_1, :pf_2, :to_sort, :to_emit, :section
        attr_reader :getPathToHere

        def initialize(route, section, pipe_function)
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
          if pipe_function
            if pipe_function.arity == 1
              @pf_1 = pipe_function
              section.use_on_element = false
            else
              @pf_2 = pipe_function
            end
          else
            section.use_on_element = false
          end
        end

        def setStarts(starts)
          super
          enablePath(true) if pf_2
        end

        def processNextStart
          if pathEnabled
            while to_emit.empty?
              to_sort << [element = starts.next, starts.getCurrentPath]
            end
          else
            while to_emit.empty?
              to_sort << [starts.next, nil]
            end
          end
          raise EmptyPipe.instance if to_emit.empty?
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
          @section_element = element
        end

        def after_element
          if to_sort.any?
            if pf_1
              sorted = to_sort.sort_by do |element, path|
                pf_1.call element
              end
            elsif pf_2
              sorted = to_sort.sort_by do |element, path|
                pf_2.call_with_args element, @section_element, pf_2.wrap_path(path)
              end
            else
              sorted = to_sort.sort_by do |element, path|
                element
              end
            end
            to_emit.concat sorted
            @to_sort.clear
          end
        end
      end

      class CustomSortPipe < Pacer::Pipes::RubyPipe
        attr_reader :sort_block, :to_emit, :section, :to_sort
        attr_reader :getPathToHere

        def initialize(route, section, sort_block, graph, wrapper)
          super()
          @to_emit = []
          @section = section
          @sort_block = sort_block
          @to_sort = []
          @graph = graph
          @wrapper = wrapper
          if section
            section.visitor = self
          else
            on_element nil
          end
        end

        def setStarts(starts)
          super
          enablePath(true)
        end

        def processNextStart
          if pathEnabled
            while to_emit.empty?
              to_sort << [ element = starts.next, starts.getCurrentPath ]
            end
          else
            while to_emit.empty?
              to_sort << [ starts.next, nil ]
            end
          end
          raise EmptyPipe.instance if to_emit.empty?
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

        def after_element
          if to_sort.any?
            to_sort.map! { |e| [ @wrapper.new(@graph, e.first), e.last ] }
            sorted = to_sort.sort { |a, b| @sort_block.call a.first, b.first }
            to_emit.concat sorted.map { |e| [ e.first.element, e.last ] }
            @to_sort.clear
          end
        end
      end
    end
  end
end
