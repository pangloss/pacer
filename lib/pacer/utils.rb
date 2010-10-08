module Pacer
  module Utils
    module GraphAnalysis
      def self.structure(graph)
        result = Pacer.tg
        types = graph.v.group_count(:type).inject({}) do |hash, (type, count)|
          v = result.add_vertex nil
          v[:type] = type
          v[:count] = count
          v.graph = result
          hash[type] = v
          hash
        end
        result.v.each do |type_node|
          begin
            edges = graph.v(:type => type_node[:type]).out_e
            edge_types = edges.group_count do |e|
              [e.label, e.in_vertex[:type]]
            end
            edge_types.each do |(label, type), count|
              puts "edges #{ type_node[:type] } #{ label } #{ type }: #{ count }"
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
