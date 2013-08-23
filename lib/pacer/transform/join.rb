module Pacer
  module Routes
    module RouteOperations
      def join(&block)
        chain_route transform: Pacer::Transform::Join, block: block
      end

      def unjoin
        map { |g| g[:components] }.scatter extensions: extensions, graph: graph, element_type: element_type
      end
    end
  end

  module Transform
    module Join
      attr_reader :key_block, :unique

      def block=(block)
        @key_block = block
      end

      def uniq
        @unique = true
        self
      end

      protected

      def attach_pipe(end_pipe)
        pipe = JoinPipe.new(self, key_block, unique)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      class JoinPipe < Pacer::Pipes::RubyPipe
        attr_reader :block, :groups, :unique
        attr_accessor:to_emit

        def initialize(back, key_block, unique)
          super()
          @unique = unique
          @block = Pacer::Wrappers::WrappingPipeFunction.new back, key_block
        end

        def processNextStart
          unless to_emit
            coll = unique ? Set : Array
            groups = Hash.new { |h, k| h[k] = Pacer::GroupVertex.new k, block.graph, block.wrapper, coll.new }
            while starts.hasNext
              el = starts.next
              groups[block.call(el)].add_component el
            end
            self.to_emit = groups.values
          end
          if to_emit.empty?
            raise Pacer::Pipes::EmptyPipe.instance
          else
            to_emit.shift
          end
        end

        def reset
          super
          self.loaded = false
          self.to_emit = nil
        end
      end
    end
  end
end

