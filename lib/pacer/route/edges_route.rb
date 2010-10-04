module Pacer
  class EdgesRoute
    include Route
    include RouteOperations
    include EdgesRouteModule

    def initialize(*args)
      @pipe_class = VertexEdgePipe
      initialize_path(*args)
    end
  end
end
