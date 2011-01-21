module Pacer
  # Import the Pipes and related objects that we'll be using.
  module Pipes
    import com.tinkerpop.pipes.AbstractPipe
    import com.tinkerpop.pipes.IdentityPipe
    import com.tinkerpop.pipes.Pipeline
    import com.tinkerpop.pipes.ExpandableIterator;

    import com.tinkerpop.pipes.filter.RandomFilterPipe
    import com.tinkerpop.pipes.filter.DuplicateFilterPipe
    import com.tinkerpop.pipes.filter.RangeFilterPipe
    import com.tinkerpop.pipes.filter.ComparisonFilterPipe
    import com.tinkerpop.pipes.filter.CollectionFilterPipe
    import com.tinkerpop.pipes.filter.FutureFilterPipe

    import com.tinkerpop.pipes.pgm.PropertyFilterPipe
    import com.tinkerpop.pipes.pgm.GraphElementPipe
    import com.tinkerpop.pipes.pgm.VertexEdgePipe
    import com.tinkerpop.pipes.pgm.EdgeVertexPipe
    import com.tinkerpop.pipes.pgm.IdPipe
    import com.tinkerpop.pipes.pgm.IdCollectionFilterPipe
    import com.tinkerpop.pipes.pgm.PropertyPipe
    import com.tinkerpop.pipes.pgm.LabelCollectionFilterPipe

    import com.tinkerpop.pipes.split.CopySplitPipe
    import com.tinkerpop.pipes.split.RobinSplitPipe
    import com.tinkerpop.pipes.merge.RobinMergePipe
    import com.tinkerpop.pipes.merge.ExhaustiveMergePipe

    EQUAL = ComparisonFilterPipe::Filter::EQUAL
    NOT_EQUAL = ComparisonFilterPipe::Filter::NOT_EQUAL
    #GREATER_THAN, LESS_THAN, GREATER_THAN_EQUAL, LESS_THAN_EQUAL
  end

  import java.util.Iterator
  begin
    java.util.ArrayList.new.iterator.next
  rescue NativeException => e
    NoSuchElementException = e.cause
    Pipes::NoSuchElementException = e.cause
  end
end

require 'pacer/pipe/ruby_pipe'

require 'pacer/pipe/block_filter_pipe'
require 'pacer/pipe/enumerable_pipe'
require 'pacer/pipe/expandable_pipe'
require 'pacer/pipe/group_pipe'
require 'pacer/pipe/loop_pipe'
require 'pacer/pipe/map_pipe'
require 'pacer/pipe/stream_sort_pipe'
require 'pacer/pipe/stream_uniq_pipe'
require 'pacer/pipe/type_filter_pipe'
require 'pacer/pipe/label_prefix_pipe'
require 'pacer/pipe/variable_store_iterator_wrapper'
