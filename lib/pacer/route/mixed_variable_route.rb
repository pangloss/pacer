module Pacer::Routes
  class MixedVariableRoute
    include Base
    include RouteOperations
    include MixedRouteModule
    include VariableRouteModule
  end
end
