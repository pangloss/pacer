module Pacer
  module Core
    module Route
      def gather(into = nil, &block)
        aggregate(into, &block).cap(element_type: :array)
      end
    end
  end
end
