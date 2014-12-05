module Pacer
  module Routes
    module RouteOperations
      def loop(opts = {}, &block)
        chain_route(opts.merge :filter => Pacer::Filter::LoopFilter, :looping_route => block)
      end

      def deepest(&block)
        loop(&block).deepest!
      end

      # Apply the given path fragment multiple times in succession. If a Range
      # or Array of numbers is given, the results are a combination of the
      # results from all of the specified repetition levels. That is useful if
      # a pattern may be nested to varying depths.
      def repeat(arg, &block)
        case arg
        when 0
          identity
        when Fixnum
          (0...arg).inject(self) do |route_end, count|
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

      def breadth_first(opts = {}, &block)
        min_depth = opts.fetch :min_depth, 0
        max_depth = opts.fetch :max_depth, 10
        (min_depth..max_depth).reduce(self) do |route, depth|
          route.branch do |b|
            b.repeat depth, &block
          end
        end.merge_exhaustive
      end
    end
  end

  module Filter
    module LoopFilter
      attr_reader :looping_route
      attr_accessor :while_description
      attr_reader :reverse_loop_route, :reverse_emit_route

      def help(section = nil)
        case section
        when nil
          puts <<HELP
Loops allow you to define repetative paths and paths of indeterminate length.
As a path is expanded within a loop, a control block that you define can
determine whether the given vertex should be emitted or not and whether it
should be used to continue looping or not.

There are two minor variations of the loop pipe. This is much more efficient
because it does not need to keep track of every element's path.

  g.v.
    loop { |route| route.out_e.in_v }.
    while { |element, depth| :loop_and_emit }

This is less efficient but having the path available to you can be very
powerful:

  g.v.
    loop { |route| route.out_e.in_v }.
    while { |element, depth, path| :loop_and_emit }

Control block arguments:
  element         - the element that could be emitted or looped on
  depth           - each initial element is depth 0 and has not had the loop route applied to it yet.
  path            - (optional) the full array of elements that got us to where we are

From the while block, you can give back one of three symbols:
  :loop           - loop on this element; don't include it in results
  :emit           - don't loop on this element; include it in the results
  :discard        - don't loop on this element; don't include it in the results
  :loop_and_emit  - loop on this element and include it in the results

In addition:
  false | nil     - maps to :discard
  anything else   - maps to :loop_and_emit

See the :examples section for some interesting ways to use the loop pipe.

HELP
        when :examples
          puts <<HELP
Range from 1 to 9:

  [1].to_route.loop { |r| r.map { |n| n + 1 } }.while { |n, depth| n < 10 }
  #==> 1 2 3 4 5 6 7 8 9

Why didn't this give me even numbers?

  [1].to_route.loop { |r| r.map { |n| n + 1 } }.while { |n, depth| n.even? ? :emit : :emit_and_loop }
  #==> 1 2

Odd numbers:

  [1].to_route.loop { |r| r.map { |n| n + 1 } }.while { |n, depth| n.even? ? :loop : :emit_and_loop }.limit(10)
  #==> 1  3  5  7  9  11 13 15 17 19

Fibonacci sequence:

  [[0, 1]].to_route(element_type: :path).
    loop { |r| r.map { |a, b| [b, a+b] } }.
    while { true }.limit(40).
    tails(element_type: :number)
  #==> 1         1         2         3         5         8         13        21
  #==> 34        55        89        144       233       377       610       987
  #==> 1597      2584      4181      6765      10946     17711     28657     46368
  #==> 75025     121393    196418    317811    514229    832040    1346269   2178309
  #==> 3524578   5702887   9227465   14930352  24157817  39088169  63245986  102334155

You usually won't mean to do these, but you can:

  [1].to_route.loop { |r| 123 }.while { true }.limit(10)
  #==> 123 123 123 123 123 123 123 123 123 123

  [1].to_route.loop { |r| r }.while { true }.limit(10)
  #==> 1 1 1 1 1 1 1 1 1 1

HELP
        else
          super
        end
        description
      end

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

      # this could have concurrency problems if multiple instances of the same
      # route
      def deepest!
        @loop_when_route = @looping_route
        @reverse_loop_route = false
        @emit_when_route = @looping_route
        @reverse_emit_route = true
        self
      end

      def loop_when(&block)
        @loop_when_route = Pacer::Route.block_branch(self, block)
        @reverse_loop_route = false
        self
      end

      def loop_when_not(&block)
        @loop_when_route = Pacer::Route.block_branch(self, block)
        @reverse_loop_route = true
        self
      end

      def emit_when(&block)
        @emit_when_route = Pacer::Route.block_branch(self, block)
        @reverse_emit_route = false
        self
      end

      def emit_when_not(&block)
        @emit_when_route = Pacer::Route.block_branch(self, block)
        @reverse_emit_route = true
        self
      end

      protected

      def attach_pipe(end_pipe)
        if @loop_when_route or @emit_when_route
          control_block = route_control_block
        elsif @control_block
          control_block = @control_block
        else
          fail ClientError, 'No loop control block specified. Use either #while or #until after #loop.'
        end
        pipe = Pacer::Pipes::LoopPipe.new(graph, looping_pipe, control_block)
        pipe.setStarts(end_pipe) if end_pipe
        pipe
      end

      def expandable(route = nil)
        expando = Pacer::Pipes::ExpandablePipe.new
        empty = java.util.ArrayList.new
        expando.setStarts empty.iterator
        if route
          control_pipe = Pacer::Route.pipeline route
          control_pipe.setStarts expando
        else
          control_pipe = expando
        end
        [expando, control_pipe]
      end

      def route_control_block
        loop_expando, loop_pipe = expandable @loop_when_route
        emit_expando, emit_pipe = expandable @emit_when_route
        proc do |el, depth|
          loop_pipe.reset
          loop_expando.add el.element
          emit_pipe.reset
          emit_expando.add el.element
          if loop_pipe.hasNext ^ reverse_loop_route
            if emit_pipe.hasNext ^ reverse_emit_route
              :loop_and_emit
            else
              :loop
            end
          elsif depth > 0
            if emit_pipe.hasNext ^ reverse_emit_route
              :emit
            end
          end
        end
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
