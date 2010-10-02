require 'java'
require 'vendor/pipes-0.1-SNAPSHOT-standalone.jar'

module Pacer
  import com.tinkerpop.pipes.AbstractPipe
  import com.tinkerpop.pipes.filter.RandomFilterPipe
  import com.tinkerpop.pipes.filter.DuplicateFilterPipe
  import com.tinkerpop.pipes.filter.RangeFilterPipe
  import com.tinkerpop.pipes.filter.ComparisonFilterPipe
  import com.tinkerpop.pipes.pgm.PropertyFilterPipe
  import com.tinkerpop.pipes.pgm.LabelFilterPipe
  import com.tinkerpop.pipes.filter.OrFilterPipe
  import com.tinkerpop.pipes.pgm.GraphElementPipe
  import com.tinkerpop.pipes.pgm.VertexEdgePipe
  import com.tinkerpop.pipes.pgm.EdgeVertexPipe
  import java.util.NoSuchElementException

  import com.tinkerpop.blueprints.pgm.Graph;
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jGraph;
  import java.util.Iterator


  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jVertex
  import com.tinkerpop.blueprints.pgm.Vertex
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jEdge
  import com.tinkerpop.blueprints.pgm.Edge

  class Neo4jVertex
    def from_graph?(graph)
      graph.raw_graph == raw_vertex.graph_database
    end

    def inspect
      "#<V[#{name}] #{ properties.inspect }>"
    end

    def properties
      property_keys.inject({}) { |h, k| h[k] = get_property(k); h }
    end

    def name
      id
    end
  end

  module Vertex
    def [](key)
      get_property(key)
    end
  end

  class Neo4jEdge
    def inspect
      "#<E[#{id}]:#{ out_vertex.name }-#{ get_label }-#{ in_vertex.name }>"
    end

    def properties
      property_keys.inject({}) { |h, k| h[k] = get_property(k); h }
    end
  end

  module Edge
    def [](key)
      get_property(key)
    end
  end


  def self.neo4j(path)
    graph = Neo4jGraph.new(path)
    at_exit do
      begin
        graph.shutdown
      rescue Exception, StandardError => e
        pp e
      end
    end
    graph
  end

  class BlockVertexFilterPipe < AbstractPipe
    def initialize(back, block)
      @back = back
      @block = block
    end

    def processNextStart()
      while s = starts.next
        path = VertexFilterPath.new(s, @back)
        return s if yield path
      end
      raise NoSuchElementException
    end
  end


  class EnumerablePipe < AbstractPipe
    def set_enumerable(enumerable)
      case enumerable
      when Enumerable::Enumerator
        @enumerable = enumerable
      when Enumerable
        @enumerable = enumerable.to_enum
      else
        @enumerable = [enumerable].to_enum
      end
    end

    def processNextStart()
      @enumerable.next
    rescue
      raise NoSuchElementException
    end
  end


  class LabelsFilterPipe < AbstractPipe
    def set_labels(labels)
      @labels = labels.map { |label| label.to_s.to_java }
    end

    def set_starts(starts)
      @starts = starts
    end

    def processNextStart()
      while edge = @starts.next
        if @labels.include? edge.get_label
          return edge;
        end
      end
      raise NoSuchElementException
    end
  end


  class Path
    class << self
      def vertex_path(name)

      end

      def edge_path(name)

      end

      def path(name)
      end

      def pipe_filter(back, pipe_class, *args)
        f = new(back, [], nil, *args)
        f.pipe_class = pipe_class
        f
      end
    end

    include Enumerable
    attr_accessor :pipe_class

    # For debugging
    attr_reader :filters, :block, :pipe_args, :source

    def initialize(back = nil, filters = [], block = nil, *pipe_args)
      if back.is_a? Path
        @back = back
      else
        @source = back
      end
      @filters = filters
      @block = block
      @pipe_args = pipe_args
    end

    def back
      @back
    end

    def graph=(graph)
      @graph = graph
    end

    def graph
      @graph ||= @back.graph
    end

    def from_graph?(g)
      graph == g
    end

    def root?
      @back.nil?
    end

    def each
      iter = iterator
      while item = iter.next
        yield item
      end
    rescue NoSuchElementException
      self
    end

    # bias is the chance the element will be returned from 0 to 1 (0% to 100%)
    def random(bias = 0.5)
      self.class.pipe_filter(self, RandomFilterPipe, bias)
    end

    def uniq
      self.class.pipe_filter(self, DuplicateFilterPipe)
    end

    def [](prop_or_subset)
      case prop_or_subset
      when String, Symbol
        # could use PropertyPipe but that would mean supporting objects that I don't think
        # would have much purpose.
        map do |element|
          element.get_property(prop_or_subset.to_s)
        end
      when Fixnum
        self.class.new(RangeFilterPipe.new(prop_or_subset, prop_or_subset), self)
      when Range
        end_index = prop_or_subset.end
        end_index -= 1 if prop_or_subset.exclude_end?
        self.class.new(RangeFilterPipe.new(prop_or_subset.begin, end_index), self)
      when Array
      end
    end

    def iterator
      pipe = nil
      source = nil
      if @back
        source = @back.iterator
      elsif @source.is_a? Iterator
        source = @source
      elsif @source
        source = EnumerablePipe.new
        source.set_enumerable @source
      end
      if pipe_class
        pipe = pipe_class.new(*@pipe_args)
        pipe.set_starts source if source
      else
        pipe = source
      end
      filter_pipe(pipe, filters, block)
    end

    def inspect
      "#<#{self.class.name}(#{@filters.inspect}#{ @block ? ', &block' : ''})#{ @back ? ' ' + @back.inspect : ''}>"
    end

    protected

    def filter_pipe(pipe, args_array, block)
      return pipe if args_array.empty? and block.nil?
      pipe = args_array.select { |arg| arg.is_a? Hash }.inject(pipe) do |p, hash|
        hash.inject(p) do |p2, (key, value)|
          new_pipe = PropertyFilterPipe.new(key.to_s, value.to_java, ComparisonFilterPipe::Filter::NOT_EQUAL)
          new_pipe.set_starts p2
          new_pipe
        end
      end
      if block
        new_pipe = BlockFilterPipe.new(block)
        new_pipe.set_starts pipe
        pipe = new_pipe
      end
      pipe
    end
  end

  class GraphPath < Path
    def initialize(graph)
      @graph = graph
    end

    def vertices(*filters, &block)
      path = VertexPath.new(@graph.get_vertices, filters, block)
      path.pipe_class = nil
      path
    end

    def edges(*filters, &block)
      path = EdgePath.new(@graph.get_edges, filters, block)
      path.pipe_class = nil
      path
    end
  end

  class EdgePath < Path
    def initialize(*args)
      @pipe_class = VertexEdgePipe
      super
    end

    def out_v(*filters, &block)
      VertexPath.new(self, filters, block, EdgeVertexPipe::Step::OUT_VERTEX)
    end

    def in_v(*filters, &block)
      VertexPath.new(self, filters, block, EdgeVertexPipe::Step::IN_VERTEX)
    end

    def both_v(*filters, &block)
      VertexPath.new(self, filters, block, EdgeVertexPipe::Step::BOTH_VERTICES)
    end

    def vertices(*filters)
      raise "Can't call vertices for EdgePath."
    end

    def edges(*filters, &block)
      path = EdgePath.new(self, filters, block)
      path.pipe_class = nil
      path
    end

    def labels
      map { |e| e.get_label }
    end

    protected

    # The filters and block this processes are the ones that are passed to the
    # initialize method, not the ones passed to in_v, out_v, etc...
    def filter_pipe(pipe, filters, block)
      labels = filters.select { |arg| arg.is_a? Symbol or arg.is_a? String }
      if labels.empty?
        super
      else
        label_pipe = LabelsFilterPipe.new
        label_pipe.set_labels labels
        label_pipe.set_starts pipe
        super(label_pipe, filters - labels, block)
      end
    end
  end

  class VertexPath < Path
    def initialize(*args)
      @pipe_class = EdgeVertexPipe
      super
    end

    def out_e(*filters, &block)
      EdgePath.new(self, filters, block, VertexEdgePipe::Step::OUT_EDGES)
    end

    def in_e(*filters, &block)
      EdgePath.new(self, filters, block, VertexEdgePipe::Step::IN_EDGES)
    end

    def both_e(*filters, &block)
      EdgePath.new(self, filters, block, VertexEdgePipe::Step::BOTH_EDGES)
    end

    def vertices(*filters, &block)
      path = VertexPath.new(self, filters, block)
      path.pipe_class = nil
      path
    end

    def edges(*filters, &block)
      raise "Can't call edges for VertexPath."
    end

    def to(label, to_vertices)
      case to_vertices
      when Path
        raise "Must be from same graph" unless to_vertices.from_graph?(graph)
      when Enumerable, Iterator
        raise "Must be from same graph" unless to_vertices.first.from_graph?(graph)
      else
        raise "Must be from same graph" unless to_vertices.from_graph?(graph)
        to_vertices = [to_vertices]
      end
      map do |from_v|
        to_vertices.map do |to_v|
          graph.add_edge(nil, from_v, to_v, label) rescue nil
        end
      end
    end
  end
end
