module Pacer
  module Core
    module HashRoute
      def lengths
        map(element_type: :integer) { |h| h.length }
      end

      def keys
        map(element_type: :array) { |h| h.keys }
      end

      def values
        map(element_type: :array) { |h| h.values }
      end

      def pairs
        map(element_type: :array) { |h| h.to_a }
      end

      def [](k)
        map { |h| h[k] }
      end

      def set(k, v)
        process { |h| h[k] = v }
      end

      def fetch(k, *d, &block)
        map { |h| h.fetch(k, *d, &block) }
      end
    end
  end
end

