module Pacer::Routes
  class IndexedVerticesRoute < VerticesRoute
    def initialize(index, key, value, filters, block)
      filters = Pacer::Helpers.extract_route_conditions(filters)
      if filters.count == 1 and block.nil?
        # indexed count is possible if no other conditions
        @index = index
        @key = key
        @value = value
      end
      filters = Pacer::Helpers.remove_filter_key(filters, key)
      initialize_path(proc { r = index.get(key, value); r ? r.iterator : [] }, filters, block)
    end

    def count
      if @index and @key and @value
        @index.count(@key, @value)
      else
        super
      end
    end

    protected

    def route_class
      VerticesRoute
    end
  end
end
