module Pacer
  module Routes
    module RouteOperations
      def loop(&block)
        chain_route :filter => :loop, :looping_route => block
      end

      # Apply the given path fragment multiple times in succession. If a Range
      # or Array of numbers is given, the results are a combination of the
      # results from all of the specified repetition levels. That is useful if
      # a pattern may be nested to varying depths.
      def repeat(arg, &block)
        case arg
        when Fixnum
          range = arg..arg
          arg.to_enum(:times).inject(self) do |route_end, count|
            yield route_end
          end
        when Range
          if arg.exclude_end?
            range = arg.begin..(arg.end - 1)
          else
            range = arg
          end
          r = self.loop(&block).while do |e, depth, p|
            if depth < range.begin
              :loop
            elsif depth < range.end
              :loop_and_emit
            elsif depth == range.end
              :emit
            else
              false
            end
          end
          r.while_description = "repeat #{ arg.inspect }"
          r
        else
          fail ArgumentError, "Invalid repeat range"
        end
      end
    end
  end

  module Filter
    module LoopFilter
      attr_reader :looping_route
      attr_accessor :while_description

      def looping_route=(route)
        if route.is_a? Proc
          @looping_route = Pacer::Route.block_branch(self, route)
        else
          @looping_route = route
        end
      end

      def while(&block)
        @control_block = block
        self
      end

      protected

      def attach_pipe(end_pipe)
        unless @control_block
          fail ClientError, 'No loop control block specified. Use either #while or #until after #loop.'
        end

        pipe = Pacer::Pipes::LoopPipe.new(graph, looping_pipe, @control_block)
        pipe.setStarts(end_pipe) if end_pipe
        pipe
      end

      def looping_pipe
        Pacer::Route.pipeline(looping_route)
      end

      def inspect_string
        s = "#{ inspect_class_name }(#{ @looping_route.inspect })"
        if while_description
          "#{ s }(#{ while_description })"
        else
          s
        end
      end
    end
  end
end
