module Pacer
  module Extensions
    module Disconnected
      module Element
        def replay
          @replay = ReplayGraph.new(graph) unless defined? @replay
          @replay
        end
      end

      module Vertex
        V = com.tinkerpop.blueprints.pgm.Vertex
        include Element

        def initialize(element = nil)
          if element.is_a? V
            @element = element
          else
            @element ||= replay.create_vertex
            @element.properties = element if element.is_a? Hash
          end
          after_initialize
        end
      end

      module Edge
        include Element
      end
    end
  end
end
