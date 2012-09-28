module Pacer
  module Core
    module Graph
      module PathRoute
        def combine(*exts)
          chain_route transform: :combine_path
        end
      end
    end
  end

  module Transform
    module CombinePath
      protected

      def attach_pipe(end_pipe)
        pipe = CombinePathPipe.new
        pipe.setStarts end_pipe
        pipe
      end


      class CombinePathPipe < RubyPipe
        def initialize
          super
          self.building_path = nil
          self.prev_path = nil
        end

        # NOTE: doesn't handle variable length paths yet...
        def processNextStart()
          while true
            path = starts.next
            if building_path
              if path.first == building_path.first.first
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
            building_path
          else
            raise EmptyPipe.instance
          end
        end

        private

        attr_accessor :building_path, :prev_path

        def make(path)
          path.reverse.inject([]) { |inner, e| [e, inner] }
        end

        def add_path(path)
          working = building_path
          path.length.times do |pos|
            current = path[pos]
            prev = prev_path[pos]
            if current == prev
              working = working.last
            else
              working << make(path[pos..-1])
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


  [a [b [c]
        [d]]
     [e [f
         g]]]



