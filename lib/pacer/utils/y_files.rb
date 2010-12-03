require 'nokogiri'
require 'set'

module Pacer
  module Utils

    # Exports a graph to GraphML with some yworks.com graphml formatting extensions.
    class YFilesExport

      # a proc that takes a vertex and returns a label string
      attr_accessor :vertex_label
      # a proc that takes a vertex and returns a color in hex format: "#aaee00"
      attr_accessor :vertex_fill
      # a proc that takes a vertex and returns a hash of properties to be exported
      attr_accessor :vertex_properties

      # a proc that takes an edge and returns a label string
      attr_accessor :edge_label
      # a proc that takes an edge and returns a color in hex format: "#aaee00"
      attr_accessor :edge_color
      # a proc that takes an edge and returns a hash of properties to be exported
      attr_accessor :edge_properties

      def initialize
        self.vertex_label = proc { |v| v[:name] }
        self.edge_label = proc { |e| e.label }
        self.vertex_properties = self.edge_properties = proc { |x| x.properties }
        self.vertex_fill = proc { |v| "#FFCC00" }
        self.edge_color = proc { |e| "#000000" }
      end

      # Export the given graph to the given path in an extended .graphml format.
      def export(graph, path)
        x = xml(graph)
        File.open(File.expand_path(path), 'w') do |f|
          f.puts x.to_xml
        end
      end

      # Returns the xml builder used to construct the xml for the given graph.
      def xml(graph)
        node_keys = Set[]
        edge_keys = Set[]
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.graphml('xmlns' => "http://graphml.graphdrawing.org/xmlns",
                      'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                      'xmlns:y' => "http://www.yworks.com/xml/graphml",
                      'xsi:schemaLocation' => "http://graphml.graphdrawing.org/xmlns http://www.yworks.com/xml/schema/graphml/1.1/ygraphml.xsd") do
            xml.key 'for' => "node", 'id' => "y.nodegraphics", 'yfiles.type' => "nodegraphics"
            xml.key 'attr.name' => "description", 'attr.type' => "string", 'for' => "node", 'id' => "d2"
            xml.key 'for' => "edge", 'id' => "y.edgegraphics", 'yfiles.type' => "edgegraphics"
            graph.v.each do |v|
              xml.node :id => v.id do
                xml.data :key => 'y.nodegraphics' do
                  xml['y'].ShapeNode do
                    #xml['y'].Geometry 'height' => "30.0", 'width' => "30.0", 'x' => "15.0", 'y' => "0.0"
                    xml['y'].Fill 'color' => vertex_fill.call(v), 'transparent' => "false"
                    xml['y'].BorderStyle 'color' => "#000000", 'type' => "line", 'width' => "1.0"
                    xml['y'].NodeLabel('alignment' => "center",
                                       'autoSizePolicy' => "content",
                                       'fontFamily' => "Dialog",
                                       'fontSize' => "12",
                                       'fontStyle' => "plain",
                                       'hasBackgroundColor' => "false",
                                       'hasLineColor' => "false",
                                       #'height' => "4.0",
                                       'modelName' => "internal",
                                       'modelPosition' => "c",
                                       'textColor' => "#000000",
                                       'visible' => "true"
                                       #'width' => "4.0",
                                       #'x' => "13.0",
                                       #'y' => "13.0"
                                      ) { xml.text vertex_label.call(v) }
                    xml['y'].Shape 'type' => "rectangle"
                  end
                end
                vertex_properties.call(v).each do |name, value|
                  node_keys << name
                  xml.data(:key => name) { xml.text value }
                end
              end
            end
            graph.e.each do |e|
              xml.edge :id => e.id, :source => e.out_v.id, :target => e.in_v.id, :label => e.label do
                xml.data :key => 'y.edgegraphics' do
                  xml['y'].PolyLineEdge do
                    xml['y'].LineStyle 'color' => edge_color.call(e), 'type' => 'line', 'width' => '1.0'
                    xml['y'].Arrows 'source' => 'none', 'target' => 'standard'
                    xml['y'].EdgeLabel('alignment' => "center",
                                       #'distance' => "2.0",
                                       'fontFamily' => "Dialog",
                                       'fontSize' => "12",
                                       'fontStyle' => "plain",
                                       'hasBackgroundColor' => "false",
                                       'hasLineColor' => "false",
                                       #'height' => "18.1328125",
                                       'modelName' => "side_slider",
                                       #'preferredPlacement' => "right",
                                       #'ratio' => "0.43751239324621083",
                                       'textColor' => "#000000",
                                       'visible' => "true"
                                       #'width' => "28.87890625",
                                       #'x' => "49.62109375",
                                       #'y' => "-27.201349990172957"
                                      ) { xml.text edge_label.call(e) }
                  end
                end
                edge_properties.call(e).each do |name, value|
                  edge_keys << name
                  xml.data(:key => name) { xml.text value }
                end
              end
            end

            node_keys.each do |key|
              xml.key :id => key, :for => 'node', 'attr.name' => key, 'attr.type' => 'string'
            end
            edge_keys.each do |key|
              xml.key :id => key, :for => 'edge', 'attr.name' => key, 'attr.type' => 'string'
            end
          end
        end
      end
    end
  end
end
