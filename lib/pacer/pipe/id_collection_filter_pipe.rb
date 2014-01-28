module Pacer::Pipes
  class IdCollectionFilterPipe < RubyPipe
    import com.tinkerpop.blueprints.Contains
    attr_reader :contains_in

    def initialize(ids, comparison)
      super()
      @ids = Set[*ids]
      if comparison == Contains::IN
        @contains_in = true
      elsif
        comparison == Contains::NOT_IN
        @contains_in = false
      else
        fail InternalError, "Unknown comparison type for ID collection filter"
      end
    end

    def processNextStart
      if contains_in
        while true
          element = @starts.next
          if element and @ids.include? element.getId
            return element
          end
        end
      else
        while true
          element = @starts.next
          if element and not @ids.include? element.getId
            return element
          end
        end
      end
    end
  end
end
