module Pacer::Routes
  class VerticesRoute
    include Base
    include RouteOperations
    include VerticesRouteModule

    def initialize(*args)
      @pipe_class = Pacer::Pipes::EdgeVertexPipe
      initialize_path(*args)
    end
  end
end
