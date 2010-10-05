module Pacer::Route
  class EdgesIdentityRoute
    include Base
    include RouteOperations
    include EdgesRouteModule
    include IdentityRouteModule

    def inspect_class_name
      "E"
    end
  end
end
