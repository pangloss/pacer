module Pacer
  module Routes
    module RouteOperations
      def loop(&block)
        chain_route :filter => :loop, :looping_route => block
      end

      def all(&block)
        loop(&block).while do
          :loop_and_recur
        end
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
        @deepest = true
        self
      end

      protected

      def attach_pipe(end_pipe)
        if @deepest
          control_block = deepest_control_block
        elsif @control_block
          control_block = @control_block
        else
          fail ClientError, 'No loop control block specified. Use either #while or #until after #loop.'
        end
        pipe = Pacer::Pipes::LoopPipe.new(graph, looping_pipe, control_block)
        pipe.setStarts(end_pipe) if end_pipe
        pipe
      end

      def deepest_control_block
        expando = Pacer::Pipes::ExpandablePipe.new
        empty = java.util.ArrayList.new
        expando.setStarts empty.iterator
        control_pipe = looping_pipe
        control_pipe.setStarts expando
        proc do |el|
          control_pipe.reset
          expando.add el.element
          if control_pipe.hasNext
            :loop
          else
            :emit
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
