module Pacer
  module Wrappers
    class PathWrappingPipeFunction
      include com.tinkerpop.pipes.PipeFunction

      attr_reader :block, :graph, :wrapper

      def initialize(back, block)
        @block = block
        if back
          @graph = back.graph
        end
        @wrapper = WrapperSelector.build
      end

      def arity
        block.arity
      end

      def compute(path)
        if path.first.is_a? Pacer::Wrappers::ElementWrapper
          block.call path
        else
          p = path.map do |element|
            wrapper.new graph, element
          end
          block.call p
        end
      end

      alias call compute

      def call_with_args(element, *args)
        if path.first.is_a? Pacer::Wrappers::ElementWrapper
          block.call path, *args
        else
          p = path.map do |element|
            wrapper.new graph, element
          end
          block.call p, *args
        end
      end
    end

    class PathUnwrappingPipeFunction
      include com.tinkerpop.pipes.PipeFunction

      attr_reader :block

      def initialize(block)
        @block = block
      end

      def arity
        block.arity
      end

      def compute(path)
        unwrap block.call path
      end

      alias call compute

      def call_with_args(path, *args)
        unwrap block.call path, *args
      end

      def unwrap(p)
        if p.is_a? Array
          p.map do |e|
            if e.is_a? ElementWrapper
              e.element
            else
              e
            end
          end
        elsif p.is_a? ElementWrapper
          p.element
        else
          p
        end
      end
    end
  end
end
