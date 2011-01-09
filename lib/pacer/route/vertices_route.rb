module Pacer::Routes
  class VerticesRoute
    include Base
    include RouteOperations
    include VerticesRouteModule

    def initialize(back, *pipe_args)
      @pipe_class = Pacer::Pipes::EdgeVertexPipe
      initialize_path(back, *pipe_args)
    end
  end
end
