module Pacer::Routes

  # Vertex or Edge objects are extended with this module for yielding from
  # block filters.
  module SingleRoute
    def back=(back)
      @back = back
    end

    # The previous route element.
    def back
      @back
    end

    # The vars hash contains variables that were set earlier in the processing
    # of the route. Vars may also be set within the block.
    def vars
      @back.vars
    end
  end
end
