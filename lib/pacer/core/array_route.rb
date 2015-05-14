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

#map_in             Map on each array
#reduce_in          Reduce on each array
#select_in          Select on each array
#reject_in          Reject on each array

#select_case(*cases) Simplified select on each array without needing a block
#reject_case(*cases)
    cases: the same type of objects you would give to case statements
           (ie. exact match, regex, type, etc)

#vertices(*exts)    Filter each array to only its vertices
#edges(*exts)           "        "        "       edges
#elements(*exts)        "        "        "       elements
    exts: extensions to add to the filtered elements

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

      def flatten(*opts)
        scatter(*opts)
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

      def map_in(&block)
        map element_type: element_type do |e|
          e.map(&block)
        end
      end

      def reduce_in(initial, &block)
        map { |e| e.reduce(initial, &block) }
      end

      def select_case(*cases)
        map element_type: element_type do |e|
          e.select { |x| cases.any? { |c| c === x } }
        end
      end

      def reject_case(*cases)
        map element_type: element_type do |e|
          e.reject { |x| cases.any? { |c| c === x } }
        end
      end

      def vertices(*exts)
        r = select_case Pacer::Vertex
        if exts.any?
          r.map_in { |e| e.add_extensions exts }
        else
          r
        end
      end

      def edges(*exts)
        r = select_case Pacer::Edge
        if exts.any?
          r.map_in { |e| e.add_extensions exts }
        else
          r
        end
      end

      def elements(*exts)
        r = select_case Pacer::Element
        if exts.any?
          r.map_in { |e| e.add_extensions exts }
        else
          r
        end
      end

      def select_in(&block)
        map element_type: element_type do |e|
          e.select(&block)
        end
      end

      def reject_in(&block)
        map element_type: element_type do |e|
          e.reject(&block)
        end
      end
    end
  end
end

