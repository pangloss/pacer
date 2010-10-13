module Pacer::Routes
  class IndexedVerticesRoute
    include Base
    include RouteOperations
    include VerticesRouteModule

    def initialize(index, key, value, filters, block)
      if filters == [key => value] and block.nil?
        # indexed count is possible if no other conditions
        @index = index
        @key = key
        @value = value
      end
      initialize_path(proc { r = index.get(key, value); r ? r.iterator : [] }, filters, block)
    end

    def count
      if @index and @key and @value
        @index.count(@key, @value)
      else
        super
      end
    end
  end
end
