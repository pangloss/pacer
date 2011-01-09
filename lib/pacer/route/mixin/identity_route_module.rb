module Pacer::Routes

  # Identity routes for the different element types are useful when creating a route
  # that may be applied to a different source, for instance in branch definitions or
  # in named subroutes.
  module IdentityRouteModule
    def initialize(back)
      @pipe_class = Pacer::Pipes::IdentityPipe
      @pipe_args = []
      self.back = back
    end

    # Identity routes are always considered root.
    def root?
      true
    end
  end
end
