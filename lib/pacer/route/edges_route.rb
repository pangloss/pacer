module Pacer::Routes
  class EdgesRoute
    include Base
    include RouteOperations
    include EdgesRouteModule

    # TODO: shouldn't this also pass the block to initialize_path?
    def initialize(*args)
      @pipe_class = Pacer::Pipes::VertexEdgePipe
      initialize_path(*args)
    end
  end
end
