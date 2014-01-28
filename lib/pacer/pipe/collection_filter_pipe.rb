module Pacer
  module Pipes
    module Renamed
      AbstractCollectionFilterPipe = com.tinkerpop.pipes.filter.CollectionFilterPipe
    end

    # This seemingly-useless class only exists because the class in Pipes
    # is marked abstract despite being complete.
    class CollectionFilterPipe < Renamed::AbstractCollectionFilterPipe
    end
  end
end
