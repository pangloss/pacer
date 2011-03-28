module Pacer
  module ElementMixin
    def self.included(target)
      target.send :include, Enumerable unless target.is_a? Enumerable
    end

    def extensions
      Set[]
    end

    def v(*args)
      route = super
      if args.empty? and not block_given?
        route.add_extensions extensions
      end
      route
    end

    def e(*args)
      route = super
      if args.empty? and not block_given?
        route.add_extensions extensions
      end
      route
    end

    # Specify the graph the element belongs to. For internal use only.
    def graph=(graph)
      @graph = graph
    end

    # The graph the element belongs to. Used to help prevent objects from
    # different graphs from being accidentally associated, as well as to get
    # graph-specific data for the element.
    def graph
      @graph
    end

    # Convenience method to retrieve a property by name.
    def [](key)
      value = get_property(key.to_s)
      if graph
        graph.decode_property(value)
      else
        value
      end
    end

    # Convenience method to set a property by name to the given value.
    def []=(key, value)
      value = graph.encode_property(value) if graph
      key = key.to_s
      if value
        if value != get_property(key)
          set_property(key, value)
        end
      else
        remove_property(key) if property_keys.include? key
      end
    end

    # Specialize result to return self for elements.
    def result(name = nil)
      self
    end

    # Query whether the current node belongs to the given graph.
    def from_graph?(g)
      g.equal? graph
    end

    # Returns a hash of property values by name.
    def properties
      property_keys.inject({}) { |h, name| h[name] = get_property(name); h }
    end

    def properties=(props)
      (property_keys - props.keys.collect { |k| k.to_s }).each do |key|
        remove_property key
      end
      props.each do |key, value|
        self[key] = value
      end
    end

    def element_id
      element.get_id
    end

    def ==(other)
      other.respond_to?(:element) and other.element.class == element.class and other.element_id == element_id
    end

    def <=>(other)
      display_name.to_s <=> other.display_name.to_s
    end

    def eql?(other)
      if other.respond_to? :element
        super(other.element)
      else
        super
      end
    end

    # Yields the element once or returns an enumerator containing self if no
    # block is given. Follows Ruby conventions and is meant to be used along
    # with the Enumerable mixin.
    def each
      if block_given?
        yield self
      else
        [self].to_enum
      end
    end

    def element
      self
    end
  end
end
