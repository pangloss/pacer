module Pacer
  module Core
    module HashRoute
      def lengths
        map(element_type: :integer) { |s| s.length }
      end
    end
  end
end

