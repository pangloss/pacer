module Pacer::Utils
  module Trie
    class << self
      def trie(graph, name)
        t = graph.v(self, :name => name).first
        if t
          t
        else
          graph.create_vertex self, :type => 'Trie', :name => name
        end
      end

      def route_conditions
        { :type => 'Trie' }
      end
    end

    module Vertex
      def find_word(word)
        find word.scan(/./)
      end

      def find(array)
        found = find_partial(array)
        if found.length == array.length
          found.last.in_vertex.add_extensions [Trie]
        end
      end

      def find_partial(array)
        return [] if array.empty?
        strings = array.map &:to_s
        max_depth = array.length - 1
        found = []
        v.out_e(strings.first).loop { |e| e.in_v.out_e }.while do |e, depth|
          if e.label == "trie:#{strings[depth]}" and depth <= max_depth
            found << e
            :loop
          end
        end.to_a
        found
      end

      def add_word(word)
        add word.scan(/./)
      end

      def add(array)
        found = find_partial(array)
        if found.length == array.length
          result = found.last.in_vertex
        else
          found[array.length] ||= nil
          result = array.zip(found).inject(self) do |vertex, (part, edge)|
            if edge
              edge.in_vertex
            else
              new_vertex = graph.create_vertex :type => 'Trie'
              graph.create_edge nil, vertex, new_vertex, "trie:#{part.to_s}"
              new_vertex
            end
          end
        end
        result[:end] = true
        result.add_extensions [Trie]
      end

      def path
        result = []
        v.in_e.chain_route(:pipe_class => Pacer::Pipes::LabelPrefixPipe, :pipe_args => 'trie:').loop do |e|
          e.out_v.in_e.chain_route(:pipe_class => Pacer::Pipes::LabelPrefixPipe, :pipe_args => 'trie:')
        end.while do |e, d|
          if e.out_vertex[:type] == 'Trie'
            :emit
          else
            :loop
          end
        end.paths.to_a.first.reverse.to_route(:element_type => :mixed, :graph => graph)
      end

      def array
        path.e.labels.map { |label| label[/^trie:(.*)$/, 1] }.to_a
      end

      def word
        array.join
      end
    end
  end
end
