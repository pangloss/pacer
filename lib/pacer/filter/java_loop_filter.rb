module Pacer
  module Routes
    module RouteOperations
      def java_loop(opts = {}, &block)
        chain_route(opts.merge :filter => Pacer::Filter::JavaLoopFilter, :looping_route => block)
      end

      def all(opts = {}, &block)
        if opts[:include_self]
          branch do |this|
            this
          end.branch do |this|
            this.java_loop(opts, &block)
          end.merge_exhaustive
        else
          java_loop(opts, &block)
        end
      end
    end
  end

  module Filter
    module JavaLoopFilter
      import com.tinkerpop.pipes.branch.LoopPipe

      attr_reader :looping_route

      def looping_route=(route)
        if route.is_a? Proc
          @looping_route = Pacer::Route.block_branch(self, route)
        else
          @looping_route = route
        end
      end

      def emit(always = false, &block)
        if always
          @emit_fn = proc { true }
        else
          @emit_fn = LoopPipeFunction.new graph, element_wrapper, block
        end
        self
      end

      def loop(always = false, &block)
        if always
          @loop_fn = proc { true }
        else
          @loop_fn = LoopPipeFunction.new graph, element_wrapper, block
        end
        self
      end

      protected

      def attach_pipe(end_pipe)
        pipe = LoopPipe.new(looping_pipe, loop_fn, emit_fn)
        pipe.setStarts(end_pipe) if end_pipe
        pipe
      end

      private

      def loop_fn
        @loop_fn || proc { true }
      end

      def emit_fn
        @emit_fn || proc { true }
      end

      def element_wrapper
        if back
          Pacer::Wrappers::WrapperSelector.build graph, back.element_type, back.extensions
        else
          Pacer::Wrappers::WrapperSelector.build graph
        end
      end

      def looping_pipe
        Pacer::Route.pipeline(looping_route)
      end

      class LoopPipeFunction
        attr_reader :graph, :wrapper, :block

        def initialize(graph, wrapper, block)
          @graph = graph
          @wrapper = wrapper
          @block = block
        end

        def compute(loop_bundle)
          !!(block.call LoopBundleWrapper.new(graph, wrapper, loop_bundle))
        end
      end

      class LoopBundleWrapper
        attr_reader :graph, :wrapper, :loop_bundle

        def initialize(graph, wrapper, loop_bundle)
          @graph = graph
          @wrapper = wrapper
          @loop_bundle = loop_bundle
        end

        def path
          wrap = Pacer::Wrappers::WrapperSelector.new
          loop_bundle.getPath.map { |el| wrap.new graph, el }
        end

        def depth
          loop_bundle.getLoops - 1
        end

        def element
          obj = loop_bundle.getObject
          wrapper.new graph, obj if obj
        end
      end
    end
  end
end
