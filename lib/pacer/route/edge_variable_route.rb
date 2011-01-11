module Pacer::Routes
  class EdgeVariableRoute
    include Pacer::Core::Route
    include RouteOperations
    include EdgesRouteModule
    include VariableRouteModule
  end
end
