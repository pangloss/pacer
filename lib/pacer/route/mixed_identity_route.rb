module Pacer
  class MixedIdentityRoute
    include Route
    include RouteOperations
    include MixedRouteModule
    include IdentityRouteModule

    def inspect_class_name
      "V+E"
    end
  end
end
