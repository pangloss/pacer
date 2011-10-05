module Pacer
  module Pipes
    class VisitorPipe < Pacer::Pipes::RubyPipe
      attr_reader :visitor, :queue, :in_section

      attr_accessor :use_on_element, :use_replace_element,
        :use_after_element, :use_reset, :use_hasNext, :use_next

      def initialize(visitor = nil)
        super()
        self.visitor = visitor if visitor
        @queue          = []
        @in_section = false
      end

      def visitor=(visitor)
        if visitor.respond_to? :on_pipe
          @visitor = visitor.on_pipe(self)
        else
          @visitor = visitor
        end
        @use_hasNext         = visitor.respond_to? :hasNext
        @use_next            = visitor.respond_to? :next
        @use_on_element      = visitor.respond_to? :on_element
        @use_replace_element = visitor.respond_to? :replace_element
        @use_after_element   = visitor.respond_to? :after_element
        @use_reset           = visitor.respond_to? :reset
      end

      def processNextStart
        while true
          visitor.after_element if use_after_element and in_section
          if use_next and (not use_hasNext or visitor.hasNext)
            return visitor.next
          elsif queue.any?
            return queue.shift
          else
            current = starts.next
            @in_section = true unless in_section
            visitor.on_element(current) if use_on_element
            if use_replace_element
              visitor.replace_element(current) do |e|
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
        visitor.reset if use_reset
        @in_section = false
        @queue = []
        super
      end
    end
  end
end
