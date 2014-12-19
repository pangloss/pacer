module Pacer::Pipes
  class LabelCollectionFilterPipe < RubyPipe
    def initialize(labels)
      super()
      @labels = Set[*labels]
    end

    def processNextStart
      while true
        edge = @starts.next
        return edge if edge and @labels.include? edge.getLabel
      end
    end
  end
end
