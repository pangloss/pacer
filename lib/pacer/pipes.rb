module Pacer
  # Import the Pipes and related objects that we'll be using.
  module Pipes
    # TODO: move pipe imports to the modules that actually use them.
    import com.tinkerpop.pipes.AbstractPipe
    import com.tinkerpop.pipes.transform.IdentityPipe
    import com.tinkerpop.pipes.util.Pipeline
    import com.tinkerpop.pipes.util.ExpandableIterator
    import com.tinkerpop.pipes.util.MultiIterator
    import com.tinkerpop.pipes.util.PipeHelper

    import com.tinkerpop.pipes.filter.RandomFilterPipe
    import com.tinkerpop.pipes.filter.DuplicateFilterPipe
    import com.tinkerpop.pipes.filter.RangeFilterPipe
    import com.tinkerpop.pipes.filter.FilterPipe

    import com.tinkerpop.pipes.transform.IdPipe
    import com.tinkerpop.pipes.transform.PropertyPipe

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

require 'pacer/pipe/never_pipe'
require 'pacer/pipe/block_filter_pipe'
require 'pacer/pipe/collection_filter_pipe'
require 'pacer/pipe/enumerable_pipe'
require 'pacer/pipe/expandable_pipe'
require 'pacer/pipe/group_pipe'
require 'pacer/pipe/loop_pipe'
require 'pacer/pipe/map_pipe'
require 'pacer/pipe/is_unique_pipe'
require 'pacer/pipe/stream_sort_pipe'
require 'pacer/pipe/stream_uniq_pipe'
require 'pacer/pipe/type_filter_pipe'
require 'pacer/pipe/label_collection_filter_pipe'
require 'pacer/pipe/id_collection_filter_pipe'
require 'pacer/pipe/label_prefix_pipe'
require 'pacer/pipe/variable_store_iterator_wrapper'

require 'pacer/pipe/property_comparison_pipe'
