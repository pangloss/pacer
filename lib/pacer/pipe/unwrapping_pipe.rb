module Pacer
  module Pipes
    class UnwrappingPipe < RubyPipe
      def processNextStart
        starts.next.element
      end

      def getCurrentPath
        starts.getCurrentPath
      end
    end
  end
end
