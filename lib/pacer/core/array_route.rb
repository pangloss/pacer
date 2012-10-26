module Pacer
  module Core
    module ArrayRoute
      def lengths
        map(element_type: :integer) { |s| s.length }
      end

      # This could be done more efficiently by reimplementing
      # transpose... Right now it needs 2n memory.
      def transpose
        gather { [] }.
          map(element_type: :array) { |a| a.transpose }.
          scatter(element_type: :array)
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

