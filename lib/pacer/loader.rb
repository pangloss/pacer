module Pacer
  import com.tinkerpop.blueprints.Graph
  import com.tinkerpop.blueprints.Element
  import com.tinkerpop.blueprints.Vertex
  import com.tinkerpop.blueprints.Edge

  module Core       end
  module Routes     end
  module Wrappers   end
  module Support    end
  module Visitors   end
  module Filter     end
  module Transform  end
  module SideEffect end
end


require 'pacer/exceptions'
require 'pacer/pipes'

require 'pacer/core/route'
require 'pacer/core/graph'
require 'pacer/core/side_effect'

require 'pacer/graph/graph_transactions_mixin'
require 'pacer/graph/pacer_graph'
require 'pacer/graph/simple_encoder'
require 'pacer/graph/yaml_encoder'
require 'pacer/graph/graph_ml'
require 'pacer/graph/hash_index'

require 'pacer/route/mixin/bulk_operations'
require 'pacer/route/mixin/route_operations'

require 'forwardable'
require 'pacer/wrappers/element_wrapper'
require 'pacer/wrappers/vertex_wrapper'
require 'pacer/wrappers/edge_wrapper'
require 'pacer/wrappers/index_wrapper'
require 'pacer/wrappers/wrapper_selector'
require 'pacer/wrappers/wrapping_pipe_function'

require 'pacer/route_builder'
require 'pacer/function_resolver'
require 'pacer/route'

require 'pacer/blueprints/tg'
require 'pacer/blueprints/ruby_graph'
require 'pacer/blueprints/multi_graph'

require 'pacer/support/array_list'
require 'pacer/support/enumerable'
require 'pacer/support/proc'
require 'pacer/support/hash'
require 'pacer/support/native_exception'
require 'pacer/support/nil_class'

require 'pacer/utils'

require 'pacer/visitors/visits_section'
require 'pacer/visitors/section'

require 'pacer/filter/collection_filter'
require 'pacer/filter/empty_filter'
require 'pacer/filter/future_filter'
require 'pacer/filter/property_filter'
require 'pacer/filter/range_filter'
require 'pacer/filter/uniq_filter'
require 'pacer/filter/index_filter'
require 'pacer/filter/loop_filter'
require 'pacer/filter/block_filter'
require 'pacer/filter/object_filter'
require 'pacer/filter/where_filter'
require 'pacer/filter/random_filter'

require 'pacer/transform/cap'
require 'pacer/transform/stream_sort'
require 'pacer/transform/stream_uniq'
require 'pacer/transform/gather'
require 'pacer/transform/map'
require 'pacer/transform/process'
require 'pacer/transform/join'
require 'pacer/transform/path'
require 'pacer/transform/combined_path'
require 'pacer/transform/scatter'
require 'pacer/transform/has_count_cap'
require 'pacer/transform/sort_section'

require 'pacer/side_effect/aggregate'
require 'pacer/side_effect/as'
require 'pacer/side_effect/group_count'
require 'pacer/side_effect/is_unique'
require 'pacer/side_effect/counted'
require 'pacer/side_effect/visitor'
