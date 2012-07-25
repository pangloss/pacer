module Pacer
  class RubyGraph
    import com.tinkerpop.blueprints.Element
    import com.tinkerpop.blueprints.Graph
    import com.tinkerpop.blueprints.Features

    include Graph

    FEATURES = Features.new.tap do |features|
      features.supportsDuplicateEdges = true
      features.supportsSelfLoops = true
      features.supportsSerializableObjectProperty = true
      features.supportsBooleanProperty = true
      features.supportsDoubleProperty = true
      features.supportsFloatProperty = true
      features.supportsIntegerProperty = true
      features.supportsPrimitiveArrayProperty = true
      features.supportsUniformListProperty = true
      features.supportsMixedListProperty = true
      features.supportsLongProperty = true
      features.supportsMapProperty = true
      features.supportsStringProperty = true

      features.ignoresSuppliedIds = false
      features.isPersistent = false
      features.isRDFModel = false
      features.isWrapper = false

      features.supportsIndices = false
      features.supportsKeyIndices = false
      features.supportsVertexKeyIndex = false
      features.supportsEdgeKeyIndex = false
      features.supportsVertexIndex = false
      features.supportsEdgeIndex = false
      features.supportsTransactions = false
      features.supportsVertexIteration = true
      features.supportsEdgeIteration = true
      features.supportsEdgeRetrieval = true
      features.supportsVertexProperties = true
      features.supportsEdgeProperties = true
      features.supportsThreadedTransactions = false
    end

    def initialize
      clear
    end

    def element_class
      RubyElement
    end

    def vertex_class
      RubyVertex
    end

    def edge_class
      RubyEdge
    end

    def addVertex(id)
      if id
        v_id = id
      else
        v_id = next_id
      end
      raise Pacer::ElementExists if @vertices.key? v_id
      @vertices[v_id] = vertex_class.new self, v_id
    end

    def getVertex(id)
      @vertices[id]
    end

    def removeVertex(vertex)
      @vertices.delete vertex.element_id
    end

    def getVertices
      @vertices.values.to_iterable
    end

    def addEdge(id, outVertex, inVertex, label)
      id ||= next_id
      raise Pacer::ElementExists if @edges.key? id
      @edges[id] = edge_class.new self, id, outVertex, inVertex, label
    end

    def getEdge(id)
      @edges[id]
    end

    def removeEdge(edge)
      @edges.delete edge.element_id
    end

    def getEdges
      @edges.values.to_iterable
    end

    def clear
      @vertices = {}
      @edges = {}
      @next_id = 0
    end

    def shutdown
      clear
    end

    def ==(other)
      other.equal? self
    end

    def features
      FEATURES
    end

    include GraphExtensions

    protected

    def next_id
      @next_id += 1
    end
  end

  class RubyElement
    include com.tinkerpop.blueprints.Element

    def initialize(graph, element_id)
      @graph = graph
      @element_id = element_id
      @properties = {}
    end

    def getPropertyKeys
      @properties.keys.to_hashset
    end

    def getProperty(key)
      v = @properties[key.to_s]
      if v.is_a? String
        v.dup
      else
        v
      end
    end

    def setProperty(key, value)
      @properties[key.to_s] = value
    end

    def removeProperty(key)
      @properties.delete key.to_s
    end

    def getId
      @element_id
    end

    protected

    def extract_varargs_strings(labels)
      if labels.first.is_a? ArrayJavaProxy
        labels.first.map { |l| l.to_s }
      else
        labels
      end
    end
  end


  class RubyVertex < RubyElement
    include com.tinkerpop.blueprints.Vertex
    import com.tinkerpop.blueprints.util.VerticesFromEdgesIterable

    def getRawVertex
      self
    end

    def getVertices(direction, *labels)
      VerticesFromEdgesIterable.new self, direction, *labels
    end

    def getEdges(direction, *labels)
      labels = extract_varargs_strings(labels)
      if direction == Pacer::Pipes::BOTH
        edges = graph.getEdges.select do |e|
          ( (e.getVertex(Pacer::Pipes::IN) == self or e.getVertex(Pacer::Pipes::OUT) == self) and
            (labels.empty? or labels.include? e.getLabel) )
        end
      else
        edges = graph.getEdges.select { |e| e.getVertex(direction) == self and (labels.empty? or labels.include? e.getLabel) }
      end
      Pacer::Pipes::EnumerablePipe.new edges
    end

    include VertexExtensions
  end

  class RubyEdge < RubyElement
    include com.tinkerpop.blueprints.Edge

    def initialize(graph, id, out_vertex, in_vertex, label)
      super(graph, id)
      @out_vertex = out_vertex
      @in_vertex = in_vertex
      @label = label.to_s
    end

    def getRawEdge
      self
    end

    def getLabel()
      @label
    end

    def getVertex(direction)
      if direction == Pacer::Pipes::OUT
        @out_vertex
      else
        @in_vertex
      end
    end

    include EdgeExtensions
  end
end
