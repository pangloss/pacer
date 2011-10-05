module Pacer
  module Routes
    module RouteOperations
      def section(section_name = nil)
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
          @in_section = false
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
          @in_section = false
          super
        end

        protected

        def processNextStart
          fire(@end_procs) if @in_section
          @current = @starts.next
          @in_section = true
          @count += 1
          fire(@start_procs)
          @current
        rescue NativeException => e
          if e.cause.getClass == Pacer::NoSuchElementException.getClass
            @in_section = false
            raise e.cause
          else
            raise
          end
        end

        def fire(procs)
          procs.each { |proc| proc.call @current, @count }
        end
      end

      attr_writer :section_name

      def section_name
        @section_name = "section_#{ object_id }" unless defined? @section_name
        @section_name
      end

      protected

      attr_reader :section_events

      def attach_pipe(end_pipe)
        @section_events = pipe = SectionPipe.new(section_name)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
