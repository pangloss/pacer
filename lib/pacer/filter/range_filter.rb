module Pacer
  module Routes
    module RouteOperations
      def range(from, to)
        args = { :back => self, :filter => :range }
        args[:begin] = from if from
        args[:end] = to if to
        chain_route args
      end
    end
  end

  module Filter
    module RangeFilter
      def self.triggers
        [:range]
      end

      def range=(range)
        @range = range
      end

      def begin=(n)
        @range = n..range.end
      end

      def end=(n)
        @range = range.begin..n
      end

      def index=(index)
        @range = index..index
      end

      def range
        @range ||= -1..-1
      end

      protected

      def attach_pipe(end_pipe)
        from = @range.begin
        to = @range.end
        to += 1 unless @range.exclude_end? if to >= 0
        pipe = Pacer::Pipes::RangeFilterPipe.new from, to
        pipe.set_starts end_pipe
        pipe
      end
    end
  end
end
