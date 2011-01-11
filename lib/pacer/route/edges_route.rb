module Pacer::Routes
  class EdgesRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::EdgesRoute

    # TODO: shouldn't this also pass the block to initialize_path?
    def initialize(back, *pipe_args)
      @pipe_class = Pacer::Pipes::VertexEdgePipe
      initialize_path(back, *pipe_args)
    end
  end
end
