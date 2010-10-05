module Pacer::Route
  class EdgeVariableRoute
    include Base
    include RouteOperations
    include EdgesRouteModule
    include VariableRouteModule
  end
end
