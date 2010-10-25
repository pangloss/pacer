module Pacer::Routes
  class ContextRoute
    include Base

    def initialize(back)
      @back = back
    end

    alias each each_context

    def root?
      false
    end

    protected

    def has_routable_class?
      false
    end
  end
end
