module Pacer::Routes
  class EdgeVariableRoute
    include Base
    include RouteOperations
    include EdgesRouteModule
    include VariableRouteModule
  end
end
