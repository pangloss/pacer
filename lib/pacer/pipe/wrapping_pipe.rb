module Pacer
  module Pipes
    class WrappingPipe < RubyPipe
      attr_reader :graph, :element_type
      attr_accessor :wrapper

      def initialize(graph, element_type = nil, extensions = [])
        super()
        @graph = graph
        @element_type = element_type
        @wrapper = Pacer::Wrappers::WrapperSelector.build element_type, extensions
      end

      def processNextStart
        e = wrapper.new starts.next
        if element_type == :vertex or element_type == :edge or element_type == :mixed
          e.graph = graph
        elsif e.respond_to? :graph=
          e.graph = graph
        end
        e
      rescue NativeException => e
        if e.cause.getClass == Pacer::NoSuchElementException.getClass
          raise e.cause
        else
          raise e
        end
      end
    end
  end
end
