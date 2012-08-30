module Pacer::Wrappers
  class ElementWrapper
    include Pacer::Element
    extend Forwardable
    include Comparable
    include Pacer::Routes::RouteOperations
    include Pacer::Core::Graph::ElementRoute

    class << self
      def wrap(element, exts)
        if element.respond_to? :element
          wrapper_for(exts).new(element.element)
        else
          wrapper_for(exts).new(element)
        end
      end

      def extensions
        @extensions ||= []
      end

      def add_extensions(exts)
        wrapper_for(extensions + exts.to_a)
      end

      def clear_cache
        Pacer.send :remove_const, :Wrap if Pacer.const_defined? :Wrap
        VertexWrapper.clear_cache
        EdgeWrapper.clear_cache
      end

      def route_conditions
        return @route_conditions if defined? @route_conditions
        @route_conditions = extensions.inject({}) do |h, ext|
          if ext.respond_to? :route_conditions
            h.merge! ext.route_conditions
          else
            h
          end
        end
        @route_conditions
      end

      protected

      def build_extension_wrapper(exts, mod_names, superclass)
        sc_name = superclass.to_s.split(/::/).last
        exts = exts.uniq unless exts.is_a? Set
        classname = "#{sc_name}#{exts.map { |m| m.to_s }.join('')}".gsub(/::/, '_').gsub(/\W/, '')
        begin
          wrapper = Pacer::Wrap.const_get classname
        rescue NameError
          eval %{
            module ::Pacer
              module Wrap
                class #{classname.to_s} < #{sc_name}
                end
              end
            end
          }
          wrapper = Pacer::Wrap.const_get classname
        end
        exts.each do |obj|
          if obj.is_a? Module or obj.is_a? Class
            mod_names.each do |mod_name|
              if obj.const_defined? mod_name
                wrapper.send :include, obj.const_get(mod_name)
                wrapper.extensions << obj unless wrapper.extensions.include? obj
              end
            end
          end
        end
        wrapper
      end
    end

    # For internal use only.
    #
    # The graph the element belongs to.
    #
    # Used to help prevent objects from different graphs from being
    # accidentally associated, as well as to get graph-specific data for
    # the element.
    #
    # @return [PacerGraph]
    attr_accessor :graph
    attr_reader :element

    def initialize(element)
      if element.is_a? ElementWrapper
        @element = element.element
      else
        @element = element
      end
      after_initialize
    end

    def hash
      element.hash
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
        graph.decode_property(value)
      end
    end

    # Convenience method to set a property by name to the given value.
    # @param [#to_s] key the property name
    # @param [Object] value the value to set the property to
    def []=(key, value)
      value = graph.encode_property(value)
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
    # @return [ElementWrapper] self
    def result(name = nil)
      self
    end

    # Query whether the current node belongs to the given graph.
    #
    # @param [Object] g the object to compare to {#graph}
    def from_graph?(g)
      g.blueprints_graph.equal? graph.blueprints_graph
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

    # Sort objects semi arbitrarily based on {#display_name}.
    # @param other
    #
    # @return [Fixnum]
    def <=>(other)
      display_name.to_s <=> other.display_name.to_s
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
      if other.respond_to? :element_id
        other.graph == graph and other.element_id == element_id
      else
        element.equals other
      end
    end

    protected

    def after_initialize
    end
  end
end
