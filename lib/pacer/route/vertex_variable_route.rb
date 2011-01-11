module Pacer::Routes
  class VertexVariableRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::VerticesRoute
    include VariableRouteModule
  end
end
