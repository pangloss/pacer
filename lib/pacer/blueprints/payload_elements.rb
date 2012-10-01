module Pacer
  module Payload
    class Element
      include com.tinkerpop.blueprints.Element
      extend Forwardable

      def initialize(element, payload = nil)
        @element = element
        self.payload = payload
      end

      def inspect
        "#<Payload #{ element.inspect } -- #{ payload.inspect }>"
      end

      attr_reader :element
      attr_accessor :payload
    end

    class Edge < Element
      include com.tinkerpop.blueprints.Edge

      def_delegators :@element,
        # Object
        :equals, :toString, :hashCode,
        # Element
        :getId, :getPropertyKeys, :getProperty, :setProperty, :removeProperty, :getRawElement,
        # Edge
        :getLabel, :getVertex, :getRawEdge
    end

    class Vertex < Element
      include com.tinkerpop.blueprints.Vertex

      def_delegators :@element,
        # Object
        :equals, :toString, :hashCode,
        # Element
        :getId, :getPropertyKeys, :getProperty, :setProperty, :removeProperty, :getRawElement,
        # Vertex
        :getEdges, :getVertices, :query, :getRawVertex
    end
  end
end
