module Pacer::Routes
  class MixedVariableRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::MixedRoute
    include VariableRouteModule
  end
end
