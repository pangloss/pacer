module Pacer
  module Utils
    module GraphAnalysis

      # Returns a TinkerGraph representing the number of each type of node and how
      # many edges (by label) point to each other type of node.
      def self.structure(graph, type_field = :type)
        result = Pacer.tg
        types = graph.v.group_count(type_field).inject({}) do |hash, (type, count)|
          v = result.add_vertex nil
          v[type_field] = type
          v[:count] = count
          v.graph = result
          hash[type] = v
          hash
        end
        result.v.each do |type_node|
          begin
            edges = graph.v(type_field => type_node[type_field]).out_e
            edge_types = edges.group_count do |e|
              [e.label, e.in_vertex[type_field]]
            end
            edge_types.each do |(label, type), count|
              puts "edges #{ type_node[type_field] } #{ label } #{ type }: #{ count }"
              type_node.to(label,
                           types[type],
                           :count => count)
            end
          rescue => e
            puts e.message
          end
        end
        result
      end
    end
  end
end
