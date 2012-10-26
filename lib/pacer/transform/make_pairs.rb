module Pacer
  module Routes
    module RouteOperations
      def make_pairs(other = nil, &block)
        if block
          # This would be cool if it could create a pair based on
          fail 'not implemented yet'
        elsif other
          if other.is_a? Route and [element_type, other.element_type].all? { |t| [:vertex, :edge].include? t }
            et = :path
          else
            et = :object
          end
          other = other.to_a
          if other.empty?
            empty(self)
          else
            flat_map(element_type: et, route_name: 'make_pairs') do |el|
              other.map { |o| [el, o] }
            end
          end
        else
          fail Pacer::ClientError, 'No source for pairs given to make_pairs'
        end
      end
    end
  end
end

