module Pacer::Routes
  module IndexedRouteModule
    def initialize(index, key, value, filters, block)
      filters = extract_route_conditions(filters)
      if filters.count == 1 and block.nil?
        # indexed count is possible if no other conditions
        @index = index
        @key = key
        @value = value
      end
      filters = remove_filter_key(filters, key)
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

    def extract_route_conditions(filters)
      filters.map do |filter|
        if (filter.is_a? Module or filter.is_a? Class) and filter.respond_to? :route_conditions
          Hash[filters.first.route_conditions.map { |k, v| [k.to_s, v] }]
        else
          filter
        end
      end
    end

    def remove_filter_key(filters, key)
      filters = filters.map do |filter|
        if filter.is_a? Hash
          filter = Hash[filter.reject { |k, v| k.to_s == key.to_s }]
          if filter.empty?
            filter = nil
          end
        end
        filter
      end.compact
    end
  end
end
