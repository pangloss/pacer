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
        pipe do |pipe|
          pipe.next while pipe.unique?
        end.unique?
      end

      protected

      def attach_pipe(end_pipe)
        @pipe = Pacer::Pipes::IsUniquePipe.new
        @pipe.setStarts(end_pipe) if end_pipe
        @pipe
      end
    end
  end
end
