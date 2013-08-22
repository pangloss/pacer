module Pacer
  # Created without property support, though it could easily be added if it is ever needed.
  class GroupVertex
    import com.tinkerpop.blueprints.util.VerticesFromEdgesIterable
    IN = com.tinkerpop.blueprints.Direction::IN
    OUT = com.tinkerpop.blueprints.Direction::OUT
    BOTH = com.tinkerpop.blueprints.Direction::BOTH

    attr_reader :components
    attr_reader :paths, :wrapper, :graph

    # Initialize it with an empty set to force uniqueness. Non-unique by default.
    def initialize(id, graph, wrapper, components = nil)
      @getId = id
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

    attr_reader :getId

    def getPropertyKeys
      Set[]
    end

    def getProperty(key)
      case key
      when 'components' then components.map { |c| wrapper.new graph, c }
      when 'key' then getId
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
