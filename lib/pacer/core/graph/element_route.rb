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
      ids = element_ids.to_a
      r = ids.to_route(:info => "#{ ids.count } ids")
      r = r.chain_route(:graph => graph,
                        :element_type => element_type,
                        :pipe_class => id_pipe_class,
                        :pipe_args => [graph],
                        :route_name => 'lookup',
                        :extensions => extensions,
                        :info => [name, info].compact.join(':'))
    end

  end
end
