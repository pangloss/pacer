module Pacer
  class VerticesIdentityRoute
    include Route
    include RouteOperations
    include VerticesRouteModule
    include IdentityRouteModule

    def inspect_class_name
      "V"
    end
  end
end
