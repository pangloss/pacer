module Pacer::Routes
  class VertexVariableRoute
    include Pacer::Core::Route
    include RouteOperations
    include VerticesRouteModule
    include VariableRouteModule
  end
end
