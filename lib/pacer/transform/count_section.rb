module Pacer
  module Routes
    module RouteOperations
      def count_section(section = nil, &block)
        chain_route transform: Pacer::Transform::CountSection, key_block: block, section: section,
          element_type: :array
      end
    end
  end


  module Transform
    module CountSection
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      #  section_route
      include Pacer::Visitors::VisitsSection

      attr_accessor :key_block

      protected

      def attach_pipe(end_pipe)
        block = key_block || proc { |x| x }
        pf = Pacer::Wrappers::WrappingPipeFunction.new section_route, block
        pipe = CountSectionPipe.new(section_visitor, pf)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class CountSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :pf, :to_emit, :section, :count, :section_key

        def initialize(section, pipe_function)
          super()
          @count = 0
          @section = section
          if section
            section.visitor = self
          else
            on_element nil
          end
          @pf = pipe_function
        end

        def processNextStart
          until to_emit
            starts.next
            @count += 1
          end
          raise EmptyPipe.instance if to_emit.empty?
          emit = to_emit
          @to_emit = nil
          emit
        rescue EmptyPipe, java.util.NoSuchElementException
          if count == 0
            raise EmptyPipe.instance
          else
            after_element
            to_emit
          end
        end

        def getPathToHere
          section.getCurrentPath
        end

        def on_element(element)
          @section_key = pf.compute element
        end

        def after_element
          @to_emit = [section_key, count]
          @count = 0
        end
      end
    end
  end
end
