module Pacer::Routes
  class EdgesRoute
    include Base
    include RouteOperations
    include EdgesRouteModule

    def initialize(*args)
      @pipe_class = Pacer::Pipes::VertexEdgePipe
      initialize_path(*args)
    end
  end
end
