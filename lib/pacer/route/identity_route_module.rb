module Pacer
  module IdentityRouteModule
    def initialize(back)
      @back = back
    end

    def root?
      true
    end

    def new_identity_pipe
      @pipe = IdentityPipe.new
    end

    protected

    def iterator(is_path_iterator)
      pipe = @pipe
      raise "#new_identity_pipe must be called before #iterator" unless pipe
      pipe = yield pipe if block_given?
      if is_path_iterator
        pipe = PathIteratorWrapper.new(pipe, pipe)
      end
      pipe
    end
  end
end
