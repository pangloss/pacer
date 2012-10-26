module Pacer
  module Core
    module ArrayRoute
      def lengths
        map(element_type: :integer) { |s| s.length }
      end

      def transpose
        collect { |a| a.to_a }.transpose
      end

      def compacted
        map element_type: element_type, route_name: 'compact' do |a|
          a.compact
        end
      end

      def heads(et = nil)
        map element_type: et, route_name: 'heads' do |a|
          a.first
        end
      end

      def tails(et = nil)
        map element_type: et, route_name: 'tails' do |a|
          a.last
        end
      end

      def pairs(head = 0, tail = -1)
        map element_type: element_type, route_name: "pairs[#{ head },#{ tail }]" do |a|
          [a[head], a[tail]]
        end
      end

      def len(n)
        select do |path|
          n === path.length
        end
      end
    end
  end
end

