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
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      attr_accessor :block

      protected

      def attach_pipe(end_pipe)
        pf = Pacer::Wrappers::WrappingPipeFunction.new self, block if block
        pipe = SortSectionPipe.new(self, section_visitor, pf)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end


      class SortSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :pf_1, :pf_2, :to_sort, :to_emit, :section
        attr_reader :getPathToHere, :ready_to_sort

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
            while not ready_to_sort
              to_sort << [starts.next, starts.getCurrentPath]
            end
          else
            while not ready_to_sort
              to_sort << [starts.next, nil]
            end
          end
          sort_section if ready_to_sort
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
          @ready_to_sort = true
        end

        def sort_section
          if to_sort.any?
            @ready_to_sort = false
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
            @to_sort = []
          end
        end
      end
    end
  end
end
