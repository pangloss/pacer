module Pacer
  module Routes
    module RouteOperations
      # This method adds the IsUniquePipe to the pipeline and whenever the
      # pipeline is built, yields the pipe to the block given here.
      #
      # See #unique? below for example usage.
      def is_unique(&block)
        chain_route side_effect: :is_unique, on_build_pipe: block
      end

      # This method builds a pipe and ataches the IsUniquePipe to the end then
      # iterates the pipeline until it finds a unique element or hits the end.
      def unique?
        check = nil
        is_unique { |pipe| check = pipe }.each do
          return false unless check.isUnique
        end
        true
      end
    end
  end


  module SideEffect
    module IsUnique
      attr_accessor :on_build_pipe

      protected

      def attach_pipe(end_pipe)
        checked = Pacer::Pipes::IsUniquePipe.new
        checked.setStarts end_pipe
        on_build_pipe.call checked if on_build_pipe
        checked
      end
    end
  end
end
