module Pacer
  module Routes
    module RouteOperations
      def is_unique
        chain_route :side_effect => :is_unique
      end

      def unique?
        is_unique.unique?
      end
    end
  end


  module SideEffect
    module IsUnique
      def unique?
        checked = Pacer::Pipes::IsUniquePipe.new
        checked.setStarts pipe
        checked.next while checked.unique?
        false
      rescue Pacer::EmptyPipe, java.util.NoSuchElementException
        true
      end

      protected

      def attach_pipe(end_pipe)
        end_pipe
      end
    end
  end
end
