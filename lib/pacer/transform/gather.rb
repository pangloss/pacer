module Pacer
  module Routes::RouteOperations
    def gather
      aggregate.cap
    end
  end
end
