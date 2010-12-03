module Pacer::Routes
  class VerticesIdentityRoute
    include Base
    include RouteOperations
    include VerticesRouteModule
    include IdentityRouteModule

    protected

    def inspect_class_name
      "V"
    end
  end
end
