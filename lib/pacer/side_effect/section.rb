module Pacer
  module Routes
    module RouteOperations
      def section(section_name)
        chain_route side_effect: :section, section_name: section_name
      end
    end
  end

  module SideEffect
    module Section
      class SectionPipe < Pacer::Pipes::RubyPipe
        attr_reader :name, :count, :current

        def initialize(name)
          super()
          @name = name
          @count = 0
          @current = nil
          @start_procs = []
          @end_procs = []
        end

        def on_start(&block)
          @start_procs << block
        end

        def on_end(&block)
          @end_procs << block
        end

        def reset
          @count = 0
          @current = nil
          super
        end

        protected

        def processNextStart
          fire(@end_procs) if @count != 0
          @count += 1
          @current = @starts.next
          fire(@start_procs)
          @current
        end

        def fire(procs)
          procs.each { |proc| proc.call @current, @count }
        end
      end

      attr_accessor :section_name
      attr_reader :section_events

      protected

      def attach_pipe(end_pipe)
        @section_events = pipe = SectionPipe.new(section_name)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
