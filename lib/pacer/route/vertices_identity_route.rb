module Pacer::Routes
  class VerticesIdentityRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::VerticesRoute
    include IdentityRouteModule

    protected

    def inspect_class_name
      "V"
    end
  end
end
