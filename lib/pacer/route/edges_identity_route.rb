module Pacer::Routes
  class EdgesIdentityRoute
    include Pacer::Core::Route
    include RouteOperations
    include EdgesRouteModule
    include IdentityRouteModule

    protected

    def inspect_class_name
      "E"
    end
  end
end
