module Pacer::Route
  class VerticesRoute
    include Base
    include RouteOperations
    include VerticesRouteModule

    def initialize(*args)
      @pipe_class = Pacer::Pipe::EdgeVertexPipe
      initialize_path(*args)
    end
  end
end
