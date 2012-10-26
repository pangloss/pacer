module Pacer
  module Core
    module ArrayRoute
      def help(section = nil)
        case section
        when :arrays
          puts <<HELP
The following array route methods are available:

#lengths            Return the length of each array

#transpose          Route version of Ruby's Array#transpase

#compacted          Removes nils from each array

#heads              Route to only the first element from each array

#tails              Route to only the last element from each array

#pairs(head, tail)  Route to an array of only the head and tail elements
    head: Number    Array index of the : first  : element in the pair
    tail: Number                       : second :

#len(n)             Filter paths by length
    n: Number | Range

HELP
        else
          super
        end
        description
      end

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

