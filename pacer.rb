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
  import com.tinkerpop.pipes.pgm.GraphElementPipe
  import com.tinkerpop.pipes.pgm.VertexEdgePipe
  import com.tinkerpop.pipes.pgm.EdgeVertexPipe
  import java.util.NoSuchElementException

  import com.tinkerpop.blueprints.pgm.Graph;
  import com.tinkerpop.blueprints.pgm.impls.neo4j.Neo4jGraph;

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
      raise NoSuchElementException.new "BlockVertexFilterPipe has run out of elements."
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
      raise NoSuchElementException.new "EnumerablePipe has run out of elements."
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
      self.class.new(RandomFilterPipe.new(bias), self)
    end

    def uniq
      self.class.new(DuplicateFilterPipe.new, self)
    end

    def [](prop_or_subset)
      case prop_or_subset
      when String, Symbol
        # could use PropertyPipe but that would mean supporting objects that I don't think
        # would have much purpose.
        map do |element|
          element[prop_or_subset]
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
      elsif @source
        source = EnumerablePipe.new(@source)
      end
      if pipe_class
        pipe = pipe_class.new(*@pipe_args)
        pipe.set_start source if source
      else
        pipe = source
      end
      filter_pipe(pipe, filters, block)
    end

    def inspect
      "#<#{self.class.name} #{@filters.inspect}#{ @block ? ' &block' : ''} #{ @back.inspect }>"
    end

    protected

    def filter_pipe(pipe, args_array, block)
      return pipe if args_array.empty? and block.nil?
      pipe = args_array.select { |arg| arg.is_a? Hash }.inject(pipe) do |p, hash|
        hash.inject(p) do |p2, (key, value)|
          new_pipe = PropertyFilterPipe.new(key.to_s, value.to_s, ComparisonFilterPipe::Filter::EQUAL)
          new_pipe.set_start p2
          new_pipe
        end
      end
      if block
        new_pipe = BlockFilterPipe.new(block)
        new_pipe.set_start pipe
        pipe = new_pipe
      end
      pipe
    end
  end

  class GraphPath < Path
    def initialize(graph)
      super
    end

    def vertexes(*filters, &block)
      path = VertexPath.new(nil, filters, block, GraphElementPipe::ElementType::VERTEX)
      path.pipe_class = GraphElementPipe
      path
    end

    def edges(*filters, &block)
      path = EdgePath.new(nil, filters, block, GraphElementPipe::ElementType::EDGE)
      path.pipe_class = GraphElementPipe
      path
    end
  end

  class EdgePath < Path
    def out_v(*filters, &block)
      VertexPath.new(self, filters, block, VertexEdgePipe.Step.OUT_VERTEX)
    end

    def in_v(*filters, &block)
      VertexPath.new(self, filters, block, VertexEdgePipe.Step.IN_VERTEX)
    end

    def both_v(*filters, &block)
      VertexPath.new(self, filters, block, VertexEdgePipe.Step.BOTH_VERTEX)
    end

    def virtices(*filters)
      raise "Can't call virtices for EdgePath."
    end

    def edges(*filters, &block)
      path = EdgePath.new(@back, filters, block)
      path.pipe_class = nil
      path
    end

    protected

    # The filters and block this processes are the ones that are passed to the
    # initialize method, not the ones passed to in_v, out_v, etc...
    def filter_pipe(pipe, filters, block)
      labels = filters.select { |arg| arg.is_a? Symbol or arg.is_a? String }
      if labels.empty?
        super
      else
        new_pipe = labels.inject(pipe) do |label|
          p = LabelFilterPipe.new(label.to_s, ComparisonFilterPipe::Filter::EQUAL)
          p.set_start pipe
          p
        end
        super(new_pipe, filters - labels, block)
      end
    end
  end

  class VertexPath < Path
    def out_e(*filters, &block)
      EdgePath.new(self, filters, block, EdgeVertexPipe.Step.OUT_EDGES)
    end

    def in_e(*filters, &block)
      EdgePath.new(self, filters, block, EdgeVertexPipe.Step.IN_EDGES)
    end

    def both_e(*filters, &block)
      EdgePath.new(self, filters, block, EdgeVertexPipe.Step.BOTH_EDGES)
    end

    def virtices(*filters, &block)
      path = VertexPath.new(@back, filters, block)
      path.pipe_class = nil
      path
    end

    def edges(*filters, &block)
      raise "Can't call edges for VertexPath."
    end
  end
end
