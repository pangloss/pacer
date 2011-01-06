module Pacer::Routes
  class ObjectRoute
    include Base
    # TODO: split RouteOperations into
    # - ElementRouteOperations
    # - ObjectRouteOperations
    #include RouteOperations

    def initialize(back)
      initialize_path(back)
    end

    alias each each_object
  end
end
