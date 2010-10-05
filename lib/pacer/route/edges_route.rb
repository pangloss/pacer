module Pacer::Route
  class EdgesRoute
    include Base
    include RouteOperations
    include EdgesRouteModule

    def initialize(*args)
      @pipe_class = Pacer::Pipe::VertexEdgePipe
      initialize_path(*args)
    end
  end
end
