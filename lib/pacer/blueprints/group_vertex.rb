module Pacer
  # Created without property support, though it could easily be added if it is ever needed.
  class GroupVertex
    import com.tinkerpop.blueprints.util.VerticesFromEdgesIterable
    IN = com.tinkerpop.blueprints.Direction::IN
    OUT = com.tinkerpop.blueprints.Direction::OUT
    BOTH = com.tinkerpop.blueprints.Direction::BOTH

    attr_reader :components, :key
    attr_reader :paths, :wrapper, :graph

    # Initialize it with an empty set to force uniqueness. Non-unique by default.
    def initialize(key, graph, wrapper, components = nil)
      @key = key
      @wrapper = wrapper
      if components
        @components = components
      else
        @components = []
      end
    end

    def add_component(vertex)
      components << vertex
    end

    include com.tinkerpop.blueprints.Element

    def getId
      "#{ key }:#{ components.count }"
    end

    def getPropertyKeys
      Set[]
    end

    def getProperty(key)
      case key
      when 'components' then components.map { |c| wrapper.new graph, c }
      when 'key' then key
      when 'count' then components.count
      end
    end

    include com.tinkerpop.blueprints.Vertex

    def getRawVertex
      self
    end

    def getVertices(direction, *labels)
      VerticesFromEdgesIterable.new self, direction, *labels
    end

    def getEdges(direction, *labels)
      Pacer::Pipes::MultiPipe.new components.map { |v| v.getEdges(direction, *labels) }
    end
  end
end
