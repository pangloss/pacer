module Pacer::Routes
  class MixedElementsRoute
    include Pacer::Core::Route
    include RouteOperations
    include MixedRouteModule

    def initialize(*args)
      @pipe_class = nil
      initialize_path(*args)
    end
  end
end
