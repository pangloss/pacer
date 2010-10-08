module Pacer::Routes
  module SingleRoute
    def back=(back)
      @back = back
    end

    def back
      @back
    end

    def vars
      @back.vars
    end
  end
end
