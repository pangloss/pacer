module Pacer
  module Pipes
    module Renamed
      AbstractCollectionFilterPipe = com.tinkerpop.pipes.filter.CollectionFilterPipe
    end

    class CollectionFilterPipe < Renamed::AbstractCollectionFilterPipe
    end
  end
end
