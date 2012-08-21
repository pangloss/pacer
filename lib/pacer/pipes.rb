module Pacer
  # Import the Pipes and related objects that we'll be using.
  module Pipes
    # TODO: move pipe imports to the modules that actually use them.
    import com.tinkerpop.pipes.AbstractPipe
    import com.tinkerpop.pipes.transform.IdentityPipe
    import com.tinkerpop.pipes.util.Pipeline
    import com.tinkerpop.pipes.util.iterators.MultiIterator
    import com.tinkerpop.pipes.util.PipeHelper

    import com.tinkerpop.pipes.filter.RandomFilterPipe
    import com.tinkerpop.pipes.filter.DuplicateFilterPipe
    import com.tinkerpop.pipes.filter.RangeFilterPipe
    import com.tinkerpop.pipes.filter.FilterPipe

    import com.tinkerpop.gremlin.pipes.transform.IdPipe
    import com.tinkerpop.gremlin.pipes.transform.PropertyPipe

    IN = com.tinkerpop.blueprints.Direction::IN
    OUT = com.tinkerpop.blueprints.Direction::OUT
    BOTH = com.tinkerpop.blueprints.Direction::BOTH

    EQUAL = FilterPipe::Filter::EQUAL
    NOT_EQUAL = FilterPipe::Filter::NOT_EQUAL
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

require 'pacer/pipe/vertices_pipe'
require 'pacer/pipe/edges_pipe'

require 'pacer/pipe/never_pipe'
require 'pacer/pipe/block_filter_pipe'
require 'pacer/pipe/collection_filter_pipe'
require 'pacer/pipe/enumerable_pipe'
require 'pacer/pipe/expandable_pipe'
require 'pacer/pipe/loop_pipe'
require 'pacer/pipe/map_pipe'
require 'pacer/pipe/process_pipe'
require 'pacer/pipe/visitor_pipe'
require 'pacer/pipe/simple_visitor_pipe'
require 'pacer/pipe/is_unique_pipe'
require 'pacer/pipe/is_empty_pipe'
require 'pacer/pipe/stream_sort_pipe'
require 'pacer/pipe/stream_uniq_pipe'
require 'pacer/pipe/type_filter_pipe'
require 'pacer/pipe/label_collection_filter_pipe'
require 'pacer/pipe/id_collection_filter_pipe'
require 'pacer/pipe/label_prefix_pipe'

require 'pacer/pipe/property_comparison_pipe'

require 'pacer/pipe/blackbox_pipeline'

require 'pacer/pipe/unary_transform_pipe'
require 'pacer/pipe/cross_product_transform_pipe'

require 'pacer/pipe/wrapping_pipe'
require 'pacer/pipe/path_wrapping_pipe'
require 'pacer/pipe/unwrapping_pipe'
