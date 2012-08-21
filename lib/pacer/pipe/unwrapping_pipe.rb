module Pacer
  module Pipes
    class UnwrappingPipe < RubyPipe
      def processNextStart
        starts.next.element
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
