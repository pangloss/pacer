module Pacer
  module Core
    module StringRoute
      def lengths
        map(element_type: :integer) { |s| s.length }
      end
    end
  end
end

