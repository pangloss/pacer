module Pacer
  module Pipes
    class NakedPipe < RubyPipe
      def getCurrentPath
        starts.getCurrentPath
      end

      def processNextStart
        e = starts.next
        e = e.element if e.respond_to? :element
        if e.respond_to? :raw_vertex
          e.raw_vertex
        elsif e.respond_to? :raw_edge
          e.raw_edge
        else
          e
        end
      end
    end
  end
end
