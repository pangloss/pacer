module Pacer
  module Utils
    module GraphAnalysis

      class << self
        # Returns a TinkerGraph representing the number of each type of node and how
        # many edges (by label) point to each other type of node.
        def structure(graph, type_field = :type)
          result = Pacer.tg
          result.vertex_name = proc do |v|
            case v[:element_type]
            when 'vertex'
              "vertex '#{ v[:type] }' (#{ v[:count] })"
            when 'edge'
              "edge '#{ v[:label] }' (#{ v[:count] })"
            when 'property keys'
              if v[:keys].empty?
                "has no properties"
              else
                "has properties: #{ v[:keys].join ', ' } (#{ v[:count] })"
              end
            end
          end
          result.edge_name = proc do |e|
            if e.label == 'properties'
              "#{ e[:count] }"
            else
              "#{ e[:count] } '#{ e.label }' edges to"
            end
          end


          graph.v[type_field].fast_group_count.to_h.each do |type, count|
            result.create_vertex :element_type => 'vertex', :type_field => type_field, :type => type, :count => count
          end
          graph.e.labels.fast_group_count.to_h.each do |label, count|
            result.create_vertex :element_type => 'edge', :label => label, :count => count
          end
          result.v(:element_type => 'vertex').each do |type_node|
            puts "vertices of type #{ type_node[:type] }: #{ type_node[:count] }"
            graph.v(self, :type => type_node[:type]).property_variations result, type_node
          end
          result.v(:element_type => 'edge').each do |edge_node|
            puts "edges with label #{ edge_node[:label] }: #{ edge_node[:count] }"
            edge_route = graph.e(edge_node[:label]).e(self)
            edge_route.property_variations result, edge_node
          end
          result.v.each do |type_node|
            begin
              edges = graph.v(type_field => type_node[:type]).out_e
              edge_types = edges.group_count do |e|
                [e.label, e.in_vertex[type_field]]
              end
              edge_types.each do |(label, type), count|
                puts "edges labelled #{ label } from #{ type_node[:type] } to #{ type }: #{ count }"
                type_node.add_edges_to(label, result.v(:type => type), :count => count)
              end
            rescue => e
              puts e.message
            end
          end
          result
        end
      end

      module Route
        def property_variations(result, node)
          prop_keys = group_count { |v| v.properties.keys.sort }
          prop_keys.each do |keys, count|
            prop_key = result.v(:element_type => 'property keys').detect { |v| v[:keys] == keys }
            unless prop_key
              prop_key = result.create_vertex :element_type => 'property keys', :keys => keys, :number => keys.count, :count => 0
            end
            prop_key[:count] += count
            puts "  #{ count } with #{ keys.count } properties: #{ keys.inspect }"
            node.add_edges_to :properties, prop_key, :count => count
          end
        end
      end

      module Vertices
        def self.route_conditions(graph)
          { :element_type => 'vertex' }
        end

        module Route
          def out_edge_types
            all_edges = graph.v(Edges)
            out_e.labels.uniq.inject(all_edges) do |route, label|
              route.branch { |b| b.filter(:label => label) }
            end.v.v(Edges)
          end

          def in_edge_types
            all_edges = graph.v(Edges)
            in_e.labels.uniq.inject(all_edges) do |route, label|
              route.branch { |b| b.filter(:label => label) }
            end.v.v(Edges)
          end

          def property_variations
            out_e(:properties).in_v(Properties)
          end
        end
      end

      module Edges
        def self.route_conditions(graph)
          { :element_type => 'edge' }
        end

        module Route
          def property_variations
            out_e(:properties).in_v(Properties)
          end
        end
      end

      module Properties
        def self.route_conditions(graph)
          { :element_type => 'property keys' }
        end
      end
    end
  end
end
