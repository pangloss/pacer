module Pacer::Routes
  class EdgeVariableRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::EdgesRoute
    include VariableRouteModule
  end
end
