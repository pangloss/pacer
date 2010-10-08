module Pacer
  # Import the Pipes and related objects that we'll be using.

  import java.util.Iterator
  import java.util.NoSuchElementException

  module Pipes
    import com.tinkerpop.pipes.AbstractPipe
    import com.tinkerpop.pipes.IdentityPipe

    import com.tinkerpop.pipes.filter.RandomFilterPipe
    import com.tinkerpop.pipes.filter.DuplicateFilterPipe
    import com.tinkerpop.pipes.filter.RangeFilterPipe
    import com.tinkerpop.pipes.filter.ComparisonFilterPipe
    import com.tinkerpop.pipes.filter.CollectionFilterPipe

    import com.tinkerpop.pipes.pgm.PropertyFilterPipe
    import com.tinkerpop.pipes.pgm.GraphElementPipe
    import com.tinkerpop.pipes.pgm.VertexEdgePipe
    import com.tinkerpop.pipes.pgm.EdgeVertexPipe

    import com.tinkerpop.pipes.split.CopySplitPipe
    import com.tinkerpop.pipes.merge.RobinMergePipe
    import com.tinkerpop.pipes.merge.ExhaustiveMergePipe
  end
end

require 'pacer/pipe/path_iterator_wrapper'
require 'pacer/pipe/variable_store_iterator_wrapper'

require 'pacer/pipe/enumerable_pipe'

require 'pacer/pipe/block_filter_pipe'
require 'pacer/pipe/labels_filter_pipe'
require 'pacer/pipe/type_filter_pipe'
