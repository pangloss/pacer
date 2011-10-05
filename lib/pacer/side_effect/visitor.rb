module Pacer
  module Routes
    module RouteOperations
      def visitor(visitor)
        chain_route side_effect: :visitor, visitor: visitor
      end
    end
  end

  module SideEffect
    module Visitor
      class VisitorPipe < Pacer::Pipes::RubyPipe
        attr_reader :visitor, :queue, :has_on_element, :has_after_element, :has_reset, :has_hasNext, :has_next

        def initialize(visitor)
          super()
          if visitor.respond_to? :on_pipe
            @visitor = visitor.on_pipe(self)
          else
            @visitor = visitor
          end
          @has_on_element     = @visitor.respond_to? :on_element
          @has_after_element  = @visitor.respond_to? :after_element
          @has_reset          = @visitor.respond_to? :reset
          @has_hasNext        = @visitor.respond_to? :hasNext
          @has_next           = @visitor.respond_to? :next
          @queue          = []
          @in_section = false
        end

        def processNextStart
          while true
            visitor.after_element if has_after_element and @in_section
            if has_next and (not has_hasNext or visitor.hasNext)
              return visitor.next
            elsif queue.any?
              return queue.shift
            else
              current = @starts.next
              has_in_section = true
              if has_on_element
                visitor.on_element(current) do |e|
                  queue << e
                end
              else
                return current
              end
            end
          end
        rescue NativeException => e
          if e.cause.getClass == Pacer::NoSuchElementException.getClass
            @in_section = false
            raise e.cause
          else
            raise
          end
        end

        def reset
          visitor.reset if has_reset
          @in_section = false
          @queue = []
          super
        end
      end

      attr_reader :visitor

      def visitor=(v)
        @visitor = v
        @visitor = @visitor.on_route(self) if @visitor.respond_to? :on_route
      end

      def element_type
        if @visitor.respond_to? :element_type
          @visitor.element_type
        else
          super
        end
      end

      protected

      def attach_pipe(end_pipe)
        pipe = @visitor.attach_pipe(end_pipe) if @visitor.respond_to? :attach_pipe
        pipe ||= VisitorPipe.new(visitor)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end
    end
  end
end
