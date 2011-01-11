module Pacer::Routes
  class EdgesIdentityRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::EdgesRoute
    include IdentityRouteModule

    protected

    def inspect_class_name
      "E"
    end
  end
end
