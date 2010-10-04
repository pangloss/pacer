module Pacer
  class VerticesRoute
    include Route
    include RouteOperations
    include VerticesRouteModule

    def initialize(*args)
      @pipe_class = EdgeVertexPipe
      initialize_path(*args)
    end
  end
end
