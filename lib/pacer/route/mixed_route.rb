module Pacer::Routes
  class MixedRoute
    include Base
    include RouteOperations
    include MixedRouteModule

    def initialize(*args)
      @pipe_class = nil
      initialize_path(*args)
    end
  end
end
