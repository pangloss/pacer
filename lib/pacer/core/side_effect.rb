module Pacer
  module Core
    module SideEffect
      # Get the side effect produced by the most recently created pipe.
      # @return [Object]
      def side_effect
        @pipe.getSideEffect
      end
    end
  end
end
