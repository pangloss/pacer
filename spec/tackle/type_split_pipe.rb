module Tackle
  class TypeSplitPipe < com.tinkerpop.pipes.split.AbstractSplitPipe
    field_reader :splits

    def initialize(count)
      super(3)
    end

    def route=(r)
      @route = r
    end

    def routeNext
      if self.hasNext
        element = self.next
        case element[:type]
        when 'person'
          splits.get(0).add(element)
        when 'project'
          splits.get(1).add(element)
        else
          splits.get(2).add(element)
        end
      end
    end
  end
end
