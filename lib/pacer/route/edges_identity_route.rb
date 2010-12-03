module Pacer::Routes
  class EdgesIdentityRoute
    include Base
    include RouteOperations
    include EdgesRouteModule
    include IdentityRouteModule

    protected

    def inspect_class_name
      "E"
    end
  end
end
