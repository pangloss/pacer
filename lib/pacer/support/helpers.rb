module Pacer
  module Helpers
    class << self
      def extract_route_conditions(filters)
        filters.map do |filter|
          if filter.is_a? Module and filter.respond_to? :route_conditions
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
end
