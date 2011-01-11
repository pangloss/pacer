module Pacer::Routes
  class MixedIdentityRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::MixedRoute
    include IdentityRouteModule

    protected

    def inspect_class_name
      "V+E"
    end
  end
end
