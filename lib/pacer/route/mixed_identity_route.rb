module Pacer::Route
  class MixedIdentityRoute
    include Base
    include RouteOperations
    include MixedRouteModule
    include IdentityRouteModule

    def inspect_class_name
      "V+E"
    end
  end
end
