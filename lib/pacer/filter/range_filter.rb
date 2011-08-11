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
        chain_route :filter => :range, :limit => max
      end

      def offset(amount)
        chain_route :filter => :range, :offset => amount
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

      def limit(n = nil)
        @limit = n
        if range.begin == -1
          @range = range.begin...n
        else
          @range = range.begin...(range.begin + n)
        end
        self
      end

      def limit=(n)
        limit n
        n
      end

      def offset(n = nil)
        s = n
        s += 1 if range.begin == -1
        if range.end == -1
          @range = (range.begin + s)..-1
        elsif range.exclude_end?
          @range = (range.begin + s)...(range.end + n)
        else
          @range = (range.begin + s)..(range.end + n)
        end
        self
      end

      def offset=(n)
        offset n
        n
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
        if @range.exclude_end?
          if to == 0 
            pipe = Pacer::Pipes::NeverPipe.new
            pipe.set_starts end_pipe if end_pipe
            return pipe
          elsif to > 0
            to -= 1
          end
        end
        pipe = Pacer::Pipes::RangeFilterPipe.new from, to
        pipe.set_starts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        "#{ inspect_class_name }(#{ range.inspect })"
      end
    end
  end
end
