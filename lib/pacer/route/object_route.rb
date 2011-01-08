module Pacer::Routes
  class ObjectRoute
    include Base
    # TODO: split RouteOperations into
    # - ElementRouteOperations
    # - ObjectRouteOperations
    include RouteOperations

    def initialize(*args)
      initialize_path(*args)
    end

    alias each each_object
  end
end
