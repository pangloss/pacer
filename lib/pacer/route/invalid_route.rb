module Pacer::Routes
  class InvalidRoute
    include Base
    include RouteOperations
    include MixedRouteModule

    def initialize(back)
      @back = back
    end

    def v
      InvalidRoute.pipe_filter(self)
    end

    def e
      InvalidRoute.pipe_filter(self)
    end
  end
end
