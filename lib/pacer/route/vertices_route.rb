module Pacer::Routes
  class VerticesRoute
    include Pacer::Core::Route
    include RouteOperations
    include Pacer::Core::Graph::VerticesRoute

    def initialize(back, *pipe_args)
      @pipe_class = Pacer::Pipes::EdgeVertexPipe
      initialize_path(back, *pipe_args)
    end
  end
end
