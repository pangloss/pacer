module Pacer
  class ComposedGraph
    import com.tinkerpop.blueprints.Graph
    import com.tinkerpop.blueprints.util.wrappers.WrapperGraph


    include Graph
    include WrapperGraph

    WRAPPER_GROUPS = [
      [:event, :transactional, :indexable]
    ]

    WRAPPER_ORDER = [
      :id, :partition, :batch,
      :event, :transactional, :indexable,
      :event_indexable, :event_transactional, :event_transactional_indexable,
      :read_only,
    ]

    class << self
      def build_ns(ns, key)
        parts = key.to_s.split('_')
        first = parts.first
        name = [first, *parts[1..-1].map(&:capitalize)].join('')
        ns.__send__ name
      end

      def get_class(ns, key, suffix = '')
        name = key.to_s.split('_').map(&:capitalize).join('')
        name = "#{ name }#{ suffix }"
        ns.__send__(name)
      rescue NameError
        yield name if block_given?
      end
    end

    GRAPH_WRAPPER = Hash.new do |h, key|
      ns = build_ns com.tinkerpop.blueprints.util.wrappers, key
      h[key] = get_class ns, key, 'Graph'
    end

    VERTEX_WRAPPER = Hash.new do |h, key|
      ns = build_ns com.tinkerpop.blueprints.util.wrappers, key
      h[key] = get_class ns, key, 'Vertex'
    end

    EDGE_WRAPPER = Hash.new do |h, key|
      ns = build_ns com.tinkerpop.blueprints.util.wrappers, key
      h[key] = get_class ns, key, 'Edge'
    end

    attr_reader :extensions

    def initialize(raw_graph, extensions)
      @getBaseGraph = raw_graph
      @extensions = extensions.to_set
    end


    # INTERFACE: WrapperGraph

    attr_reader :getBaseGraph


    # INTERFACE: Graph

    def shutdown
      getBaseGraph.shutdown
    end

    def addVertex(id)
      ComposedVertex.new(self, getBaseGraph.addVertex(id))
    end

    def getVertex(id)
      vertex = getBaseGraph.getVertex(id)
      if vertex
        ComposedVertex.new(self, vertex)
      end
    end

    def getVertices
      ComposedVertexIterable.new(self, getBaseGraph.getVertices)
    end

    def getVertices(key, value)
      ComposedVertexIterable(getBaseGraph.getVertices(key, value))
    end

    def addEdge(id, outVertex, inVertex, label)
      ComposedEdge.new(self, getBaseGraph.addEdge(id, outVertex.getBaseVertex, inVertex.getBaseVertex, label))
    end

    def getEdge(id)
      edge = getBaseGraph.getEdge(id)
      if (null == edge)
        null
      else
        ComposedEdge.new(self, edge)
      end
    end

    def getEdges
      ComposedEdgeIterable.new(self, getBaseGraph.getEdges)
    end

    def getEdges(key, value)
      ComposedEdgeIterable.new(self, getBaseGraph.getEdges(key, value))
    end

    def removeEdge(edge)
      getBaseGraph.removeEdge(edge.getBaseEdge)
    end

    def removeVertex(vertex)
      getBaseGraph.removeVertex(vertex.getBaseVertex)
    end

    def toString
      "Pacer::ComposedGraph(#{ extensions.map(&:inspect).join(', ') }) #{ getBaseGraph.toString }"
    end

    def getFeatures
      features
    end
  end
end
