module Pacer::Routes
  class ObjectRoute
    include Pacer::Core::Route
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
