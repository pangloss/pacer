module Tackle
  module SimpleMixin
    module Route
      def route_mixin_method
        true
      end
    end

    module Vertex
      def vertex_mixin_method
        true
      end
    end

    module Edge
      def edge_mixin_method
        true
      end
    end
  end
end
