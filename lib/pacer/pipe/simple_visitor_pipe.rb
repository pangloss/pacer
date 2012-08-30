module Pacer
  module Pipes
    class SimpleVisitorPipe < Pacer::Pipes::RubyPipe
      attr_reader :visitor, :in_section, :wrapper

      attr_accessor :use_on_element, :use_after_element, :use_reset

      def initialize(wrapper)
        super()
        @in_section = false
        @wrapper = wrapper
      end

      def visitor=(visitor)
        @visitor = visitor
        @use_on_element      = visitor.respond_to? :on_element
        @use_after_element   = visitor.respond_to? :after_element
        @use_reset           = visitor.respond_to? :reset
      end

      def processNextStart
        visitor.after_element if use_after_element and in_section
        current = starts.next
        @in_section = true unless in_section
        visitor.on_element(wrapper.new current) if use_on_element
        return current
      rescue EmptyPipe, java.util.NoSuchElementException
        @in_section = false
        raise EmptyPipe.instance
      end

      def reset
        visitor.reset if use_reset
        @in_section = false
        super
      end
    end
  end
end
