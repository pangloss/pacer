module Pacer::Core::Graph

  module ElementRoute

    def filter(*filters, &block)
      Pacer::Route.property_filter(self, filters, block)
    end

    # v is undefined for edge routes.
    def v(*filters)
      raise Pacer::UnsupportedOperation, "Can't get vertices for this route type."
    end

    # Undefined for vertex routes.
    def e(*filters, &block)
      raise Pacer::UnsupportedOperation, "Can't get edges for this route type."
    end

    def properties
      map { |v| v.properties }
    end

    # Stores the result of the current route in a new route so it will not need
    # to be recalculated.
    def result(name = nil)
      element_ids.to_a.id_to_element_route(:based_on => self, :name => name)
    end
  end
end
