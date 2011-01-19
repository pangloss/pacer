module Pacer
  module Routes
    module RouteOperations
      def range(from, to)
        args = { :filter => :range }
        args[:begin] = from if from
        args[:end] = to if to
        chain_route args
      end

      def limit(max)
        chain_route :filter => :range, :range => (0...max)
      end

      def offset(amount)
        chain_route :filter => :range, :begin => amount
      end

      def at(pos)
        chain_route :filter => :range, :index => pos
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

      def inspect_string
        "#{ inspect_class_name }(#{ range.inspect })"
      end
    end
  end
end
