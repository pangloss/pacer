module Pacer
  module Core
    module Graph
      module PathRoute
        # Transform raw paths to a tree:
        # [a b c]
        # [a b d]
        # [a e f]
        # [a e g]
        # -- becomes --
        # [a [b [c]
        #       [d]]
        #    [e [f]
        #       [g]]]

        # The default comparator block is { |prev, current| prev == current }
        def tree(&block)
          wrapped.chain_route transform: :path_tree, element_type: :array, compare: block
        end
      end
    end
  end

  module Transform
    module PathTree
      attr_accessor :compare

      protected

      def attach_pipe(end_pipe)
        pipe = PathTreePipe.new compare
        pipe.setStarts end_pipe
        pipe
      end

      class PathTreePipe < Pacer::Pipes::RubyPipe
        def initialize(compare = nil)
          super()
          self.building_path = nil
          self.prev_path = nil
          self.compare = compare || proc { |a, b| a == b }
        end

        # NOTE: doesn't handle variable length paths yet...
        def processNextStart()
          while true
            path = starts.next
            if building_path
              if compare.call path.first, building_path.first
                add_path path
              else
                return next_path(path)
              end
            else
              next_path(path)
            end
          end
        rescue Pacer::EmptyPipe, java.util.NoSuchElementException
          if building_path
            r = building_path
            self.building_path = nil
            r
          else
            raise EmptyPipe.instance
          end
        end

        private

        attr_accessor :building_path, :prev_path, :compare

        def make(path)
          path.reverse.inject(nil) do |inner, e|
            if inner
              [e, inner]
            else
              [e]
            end
          end
        end

        def add_path(path)
          working = building_path
          (1..path.length - 1).each do |pos|
            current = path[pos]
            prev = prev_path[pos]
            if compare.call current, prev
              working = working.last
            else
              if pos < path.length
                working << make(path[pos..-1])
              else
                working << [current]
              end
              break
            end
          end
          self.prev_path = path
        end

        def next_path(path)
          finished = building_path
          self.building_path = make path
          self.prev_path = path
          finished
        end
      end
    end
  end
end

