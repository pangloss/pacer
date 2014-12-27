module Pacer
  # Import the Pipes and related objects that we'll be using.
  module Pipes
    # TODO: move pipe imports to the modules that actually use them.
    import com.tinkerpop.pipes.AbstractPipe
    import com.tinkerpop.pipes.IdentityPipe
    import com.tinkerpop.pipes.util.Pipeline
    import com.tinkerpop.pipes.util.PipeHelper

    import com.tinkerpop.pipes.filter.RandomFilterPipe
    import com.tinkerpop.pipes.filter.RangeFilterPipe
    import com.tinkerpop.pipes.filter.FilterPipe

    import com.tinkerpop.pipes.transform.IdPipe
    import com.tinkerpop.pipes.transform.PropertyPipe
    import com.tinkerpop.pipes.transform.PropertyMapPipe

    import com.xnlogic.pacer.pipes.BlackboxPipeline
    import com.xnlogic.pacer.pipes.EdgesPipe
    import com.xnlogic.pacer.pipes.CollectionFilterPipe
    import com.xnlogic.pacer.pipes.ExpandablePipe
    import com.xnlogic.pacer.pipes.IdCollectionFilterPipe
    import com.xnlogic.pacer.pipes.IsEmptyPipe
    import com.xnlogic.pacer.pipes.LabelCollectionFilterPipe
    import com.xnlogic.pacer.pipes.IsUniquePipe
    import com.tinkerpop.pipes.util.iterators.EmptyIterator
    import com.tinkerpop.pipes.transform.GatherPipe

    IN = com.tinkerpop.blueprints.Direction::IN
    OUT = com.tinkerpop.blueprints.Direction::OUT
    BOTH = com.tinkerpop.blueprints.Direction::BOTH

    import com.tinkerpop.blueprints.Compare
    EQUAL = Compare::EQUAL
    NOT_EQUAL = Compare::NOT_EQUAL
    #GREATER_THAN, LESS_THAN, GREATER_THAN_EQUAL, LESS_THAN_EQUAL
  end

  import java.util.Iterator

  EmptyPipe = com.tinkerpop.pipes.util.FastNoSuchElementException
  Pipes::EmptyPipe = EmptyPipe
end

require 'pacer/pipe/ruby_pipe'

require 'pacer/pipe/vertices_pipe'

require 'pacer/pipe/never_pipe'
require 'pacer/pipe/multi_pipe'
require 'pacer/pipe/block_filter_pipe'
require 'pacer/pipe/enumerable_pipe'
require 'pacer/pipe/loop_pipe'
require 'pacer/pipe/process_pipe'
require 'pacer/pipe/visitor_pipe'
require 'pacer/pipe/simple_visitor_pipe'
require 'pacer/pipe/stream_sort_pipe'
require 'pacer/pipe/stream_uniq_pipe'
require 'pacer/pipe/type_filter_pipe'
require 'pacer/pipe/label_prefix_pipe'

require 'pacer/pipe/property_comparison_pipe'

require 'pacer/pipe/unary_transform_pipe'
require 'pacer/pipe/cross_product_transform_pipe'

require 'pacer/pipe/wrapping_pipe'
require 'pacer/pipe/path_wrapping_pipe'
require 'pacer/pipe/unwrapping_pipe'
require 'pacer/pipe/naked_pipe'
