module Pacer::Route
  class VerticesIdentityRoute
    include Base
    include RouteOperations
    include VerticesRouteModule
    include IdentityRouteModule

    def inspect_class_name
      "V"
    end
  end
end
