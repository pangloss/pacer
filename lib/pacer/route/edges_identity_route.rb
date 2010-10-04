module Pacer
  class EdgesIdentityRoute
    include Route
    include RouteOperations
    include EdgesRouteModule
    include IdentityRouteModule

    def inspect_class_name
      "E"
    end
  end
end
