module Pacer
  # This module is mixed into the raw Blueprints Edge and Vertex classes
  # from any graph implementation.
  #
  # Adds more convenient/rubyish methods and adds support for extensions
  # to some methods where needed.
  module ElementMixin
    class << self
      protected
      def included(target)
        target.send :include, Enumerable unless target.is_a? Enumerable
      end
    end

    # Which extensions does this element have?
    # @return [Set[extensions]]
    def extensions
      Set[]
    end

    # See {Core::Graph::VerticesRoute#v}
    # @return [Route]
    def v(*args)
      route = super
      if args.empty? and not block_given?
        route.add_extensions extensions
      end
      route
    end

    # See {Core::Graph::EdgesRoute#e}
    # @return [Route]
    def e(*args)
      route = super
      if args.empty? and not block_given?
        route.add_extensions extensions
      end
      route
    end

    # For internal use only.
    #
    # Specify the graph the element belongs to.
    def graph=(graph)
      @graph = graph
    end

    # The graph the element belongs to.
    #
    # Used to help prevent objects from different graphs from being
    # accidentally associated, as well as to get graph-specific data for
    # the element.
    #
    # @return [PacerGraph]
    def graph
      @graph
    end

    # Convenience method to retrieve a property by name.
    #
    # @param [#to_s] key the property name
    # @return [Object]
    def [](key)
      if key.is_a? Array
        key.map { |k| self[k] }
      else
        value = element.getProperty(key.to_s)
        if graph
          graph.decode_property(value)
        else
          value
        end
      end
    end

    # Convenience method to set a property by name to the given value.
    # @param [#to_s] key the property name
    # @param [Object] value the value to set the property to
    def []=(key, value)
      value = graph.encode_property(value) if graph
      key = key.to_s
      if value
        if value != element.getProperty(key)
          element.setProperty(key, value)
        end
      else
        element.removeProperty(key) if element.getPropertyKeys.include? key
      end
    end

    # Specialize result to return self for elements.
    # @return [ElementMixin] self
    def result(name = nil)
      self
    end

    # Query whether the current node belongs to the given graph.
    #
    # @param [Object] g the object to compare to {#graph}
    def from_graph?(g)
      g.equal? graph
    end

    # Returns a hash of property values by name.
    #
    # @return [Hash]
    def properties
      element.getPropertyKeys.inject({}) { |h, name| h[name] = element.getProperty(name); h }
    end

    # Replace the element's properties with the given hash
    #
    # @param [Hash] props the element's new properties
    def properties=(props)
      (element.getPropertyKeys - props.keys.collect { |k| k.to_s }).each do |key|
        element.removeProperty key
      end
      props.each do |key, value|
        self[key] = value
      end
    end

    def property_keys
      getPropertyKeys
    end

    # The id of the current element
    # @return [Object] element id (type varies by graph implementation.
    def element_id
      element.getId
    end

    # Sort objects semi arbitrarily based on {VertexMixin#display_name}
    # or {EdgeMixin#display_name}.
    # @param other
    #
    # @return [Fixnum]
    def <=>(other)
      display_name.to_s <=> other.display_name.to_s
    end

    # Test equality to another object.
    #
    # Elements are equal if they are the same type and have the same id
    # and the same graph, regardless of extensions.
    #
    # If the graphdb instantiates multiple copies of the same element
    # this method will return true when comparing them.
    #
    # @see #eql?
    # @param other
    def ==(other)
      other.element_type == element_type and other.element_id == element_id and other.graph == graph
    end

    # Test object equality of the element instance.
    #
    # Wrappers/extensions (if any) are ignored, the underlying element
    # only is compared
    #
    # If the graphdb instantiates multiple copies of the same element
    # this method will return false when comparing them.
    #
    # @see #==
    # @param other
    def eql?(other)
      if other.respond_to? :element
        super(other.element)
      else
        super
      end
    end

    # Yields the element once or returns an enumerator if no block is
    # given. Follows Ruby conventions and is meant to be used along
    # with the Enumerable mixin.
    #
    # @yield [ElementMixin] this element
    # @return [Enumerator] only if no block is given
    def each
      if block_given?
        yield self
      else
        [self].to_enum
      end
    end

    # Returns the underlying element. For unwrapped elements, returns
    # self.
    # @return [ElementMixin]
    def element
      self
    end
    alias no_extensions element
  end
end
