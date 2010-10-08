module Pacer::Routes

  # Identity routes for the different element types are useful when creating a route
  # that may be applied to a different source, for instance in branch definitions or
  # in named subroutes.
  module IdentityRouteModule
    def initialize(back)
      @back = back
    end

    # Identity routes are always considered root.
    def root?
      true
    end

    # Prepare and return the current temporary identity pipe.
    def new_identity_pipe
      @pipe = Pacer::Pipes::IdentityPipe.new
    end

    protected

    # See Pacer::Routes:Base#iterator
    def iterator(is_path_iterator)
      pipe = @pipe
      raise "#new_identity_pipe must be called before #iterator" unless pipe
      pipe = yield pipe if block_given?
      if is_path_iterator
        pipe = Pacer::Pipes::PathIteratorWrapper.new(pipe, pipe)
      end
      pipe
    end
  end
end
