module Pacer::Routes
  class MixedVariableRoute
    include Pacer::Core::Route
    include RouteOperations
    include MixedRouteModule
    include VariableRouteModule
  end
end
