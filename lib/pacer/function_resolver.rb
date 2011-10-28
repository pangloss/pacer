module Pacer
  module FunctionResolver
    class << self
      def clear_cache
        @lookup_path = nil
      end

      def function(args)
        lookup_path.each do |key, map, extension|
          if value = args[key]
            function = map.fetch(value, value.is_a?(Module) && value)
            return [function, extension] if function
          end
        end
        nil
      end

      def lookup_path
        @lookup_path ||= [
          [:filter, filter_map, nil],
          [:transform, transform_map, nil],
          [:side_effect, side_effect_map, Pacer::Core::SideEffect]
        ]
      end

      def filter_map
        Hash[Pacer::Filter.constants.map { |name| [symbolize_module_name(name), Pacer::Filter.const_get(name)] }]
      end

      def side_effect_map
        Hash[Pacer::SideEffect.constants.map { |name| [symbolize_module_name(name), Pacer::SideEffect.const_get(name)] }]
      end

      def transform_map
        Hash[Pacer::Transform.constants.map { |name| [symbolize_module_name(name), Pacer::Transform.const_get(name)] }]
      end

      def symbolize_module_name(name)
        name.to_s.sub(/(Filter|SideEffect|Transform)$/, '').gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
      end
    end
  end
end
