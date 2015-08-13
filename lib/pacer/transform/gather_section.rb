module Pacer
  module Routes
    module RouteOperations
      def gather_section(section = nil, opts = {})
        wrapper = Pacer::Wrappers::WrapperSelector.build graph, element_type, extensions
        chain_route opts.merge(element_type: :array, transform: :gather_section,
                               section: section, build_wrapper: wrapper)
      end
    end
  end

  module Transform
    module GatherSection
      # VisitsSection module provides:
      #  section=
      #  section_visitor
      include Pacer::Visitors::VisitsSection

      attr_accessor :build_wrapper

      def to_id_hash
        id_pairs = paths.pairs(-2, -1).map(element_type: :array) do |(k, v)|
          [k.element_id, v.map { |e| e.element_id }]
        end
        Hash[*id_pairs.flatten]
      end

      def to_hash
        Hash[*paths.pairs(-2, -1).flatten]
      end

      protected

      def attach_pipe(end_pipe)
        # TODO: wrap gathered vertices
        pipe = GatherSectionPipe.new(section_visitor, graph, build_wrapper)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class GatherSectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :to_emit, :collecting, :collecting_path, :section, :graph, :wrapper
        attr_reader :getPathToHere

        def initialize(visitor_pipe, graph, wrapper)
          super()
          @collecting = []
          @graph = graph
          @wrapper = wrapper
          @visitor_pipe = visitor_pipe
          if visitor_pipe
            visitor_pipe.visitor = self
          end
        end

        def processNextStart
          if pathEnabled
            while !to_emit
              e = wrapper.new(graph, starts.next)
              collecting << e
              @collecting_path = @visitor_pipe.getCurrentPath
            end
          else
            while !to_emit
              e = wrapper.new(graph, starts.next)
              collecting << e
            end
          end
          if !to_emit
            raise EmptyPipe.instance
          else
            emit
          end
        rescue EmptyPipe, java.util.NoSuchElementException
          if collecting
            @collecting = nil
            emit
          else
            raise EmptyPipe.instance
          end
        end

        def emit
          e = to_emit
          @to_emit = nil
          e
        end

        def after_element
          unless collecting.empty?
            @to_emit = collecting
            @getPathToHere = collecting_path
            @collecting = []
          end
        end
      end
    end
  end
end

