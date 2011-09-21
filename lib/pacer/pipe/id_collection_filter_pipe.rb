module Pacer::Pipes
  class IdCollectionFilterPipe < RubyPipe
    def initialize(ids, comparison)
      super()
      @ids = Set[*ids]
      @comparison = comparison
    end

    def processNextStart
      if @comparison == Pacer::Pipes::EQUAL
        while true
          element = @starts.next
          if element and @ids.include? element.element_id
            return element
          end
        end
      else
        while true
          element = @starts.next
          if element and not @ids.include? element.element_id
            return element
          end
        end
      end
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
