module Pacer
  module Extensions
    module BlockFilterElement
      module Route
        def back=(back)
          @back = back
        end

        # The vars hash contains variables that were set earlier in the processing
        # of the route. Vars may also be set within the block.
        def vars
          @back.vars
        end
      end
    end
  end
end
