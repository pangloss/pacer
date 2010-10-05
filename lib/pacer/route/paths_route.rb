module Pacer::Route
  class PathsRoute
    include Base

    def initialize(back)
      @back = back
    end

    alias each each_path

    def root?
      false
    end

    def transpose
      to_a.transpose
    end

    protected

    def has_routable_class?
      false
    end
  end
end
