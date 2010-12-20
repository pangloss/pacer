module Pacer::Routes
  class IndexedEdgesRoute < EdgesRoute
    include IndexedRouteModule

    protected

    def route_class
      EdgesRoute
    end
  end
end
