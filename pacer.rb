module Pacer
  class BlockVertexFilterPipe < AbstractPipe
    def initialize(back, block)
      @back = back
      @block = block
    end

    def processNextStart()
      while s = starts.next
        path = VertexFilterPath.new(s, back)
        return s if yield path
      end
    end
  end

  class SingleElementPipe < AbstractPipe
    def initialize(element)
      @element = element
    end

    def processNextStart()
      element, @element = @element, nil
      element
    end
  end

  class Path
    include Enumerable

    class << self
      def vertex_path(name)

      end

      def edge_path(name)

      end

      def path(name)
      end
    end

    def initialize(pipe, back = nil)
      @back = back
      if pipe.is_a? Pipe
        @pipe = pipe
      else
      end
    end

    def back
      @back
    end

    def root?
      @back.nil?
    end

    def each
      @pipe.to_enum(:each)
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
    def vertexes(*filters, &block)
      pipe = GraphElementPipe.new(GraphElementPipe.ElementType.VERTEX);
      VertexPath.new(filter_pipe(pipe, filters, block), self)
    end

    def edges(*filters, &block)
      pipe = GraphElementPipe.new(GraphElementPipe.ElementType.EDGE);
      EdgePath.new(filter_pipe(pipe, filters, block), self)
    end
  end

  class EdgePath < Path
    def out_v(*filters, &block)
      pipe = VertexEdgePipe.new(VertexEdgePipe.Step.OUT_VERTEX)
      pipe.set_start = @pipe
      VertexPath.new(filter_pipe(pipe, filters, block), self)
    end

    def in_v(*filters, &block)
      pipe = VertexEdgePipe.new(VertexEdgePipe.Step.IN_VERTEX)
      pipe.set_start = @pipe
      VertexPath.new(filter_pipe(pipe, filters, block), self)
    end

    def both_v(*filters, &block)
      pipe = VertexEdgePipe.new(VertexEdgePipe.Step.BOTH_VERTICES)
      pipe.set_start = @pipe
      VertexPath.new(filter_pipe(pipe, filters, block), self)
    end

    def virtices(*filters)
      raise "Can't call virtices for EdgePath."
    end

    def edges(*filters, &block)
      EdgePath.new(filter_pipe(@pipe, filters, block), back)
    end

    protected

    def filter_pipe(pipe, args_array, block)
      labels = args_array.select { |arg| arg.is_a? Symbol or arg.is_a? String }
      if labels.empty?
        super
      else
        new_pipe = labels.inject(pipe) do |label|
          p = LabelFilterPipe.new(label.to_s, ComparisonFilterPipe::Filter::EQUAL)
          p.set_start pipe
          p
        end
        super(new_pipe, args_array - labels, block)
      end
    end
  end

  class VertexPath < Path
    def out_e(*filters, &block)
      pipe = EdgeVertexPipe.new(EdgeVertexPipe.Step.OUT_EDGES)
      pipe.set_start = @pipe
      EdgePath.new(filter_pipe(pipe, filters, block), self)
    end

    def in_e(*filters, &block)
      pipe = EdgeVertexPipe.new(EdgeVertexPipe.Step.IN_EDGES)
      pipe.set_start = @pipe
      EdgePath.new(filter_pipe(pipe, filters, block), self)
    end

    def both_e(*filters, &block)
      pipe = EdgeVertexPipe.new(EdgeVertexPipe.Step.BOTH_EDGES)
      pipe.set_start = @pipe
      EdgePath.new(filter_pipe(pipe, filters, block), self)
    end

    def virtices(*filters, &block)
      VertexPath.new(filter_pipe(@pipe, filters, block), back)
    end

    def edges(*filters, &block)
      raise "Can't call edges for VertexPath."
    end
  end
end
