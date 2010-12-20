module Pacer::Routes
  class IndexedVerticesRoute < VerticesRoute
    include IndexedRouteModule

    protected

    def route_class
      VerticesRoute
    end
  end
end
