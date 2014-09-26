module Pacer::Wrappers
  class ElementWrapper
    include Pacer::Element
    extend Forwardable
    include Comparable
    include Pacer::Routes::RouteOperations
    include Pacer::Core::Graph::ElementRoute

    class << self
      attr_accessor :caches

      def base_vertex_wrapper
        VertexWrapper
      end

      def base_edge_wrapper
        EdgeWrapper
      end

      def wrap(element, exts)
        wrapper_for(exts).new(element.graph, element.element)
      end

      def extensions
        @extensions ||= []
      end

      def add_extensions(exts)
        wrapper_for(extensions + exts.to_a)
      end

      def clear_cache
        VertexWrapper.clear_cache
        EdgeWrapper.clear_cache
        caches.each { |c| c.clear_cache } if caches
      end

      def route_conditions(graph)
        return @route_conditions if defined? @route_conditions
        @route_conditions = extensions.inject({}) do |h, ext|
          if ext.respond_to? :route_conditions
            h.merge! ext.route_conditions(graph)
          else
            h
          end
        end
        @route_conditions
      end

      def lookup(graph)
        return @lookup if defined? @lookup
        @lookup = extensions.inject({}) do |h, ext|
          if ext.respond_to? :lookup
            h.merge! ext.lookup(graph)
          else
            h
          end
        end
        @lookup
      end

      protected

      def build_extension_wrapper(exts, mod_names, superclass)
        sc_name = superclass.to_s.split(/::/).last
        exts = exts.uniq unless exts.is_a? Set
        Class.new(superclass) do
          exts.each do |obj|
            if obj.is_a? Module or obj.is_a? Class
              mod_names.each do |mod_name|
                if obj.const_defined? mod_name
                  include obj.const_get(mod_name)
                  extensions << obj unless extensions.include? obj
                end
              end
            end
          end
        end
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
    attr_reader :graph
    attr_reader :element

    def initialize(graph, element)
      @graph = graph
      if element.is_a? ElementWrapper
        @element = element.element
      else
        @element = element
      end
      after_initialize
    end

    def chain_route(args_hash)
      Pacer::RouteBuilder.current.chain self, args_hash
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
      begin
        value = graph.encode_property(value)
      rescue Exception => e
        throw Pacer::ClientError.new "Unable to serialize #{ key }: #{ value.class }"
      end
      key = key.to_s
      if value.nil?
        element.removeProperty(key)
      else
        element.setProperty(key, value)
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
      Hash[element.getPropertyKeys.map { |name| [name, graph.decode_property(element.getProperty(name))] }]
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

    def element_payload
      element.payload if element.is_a? Pacer::Payload::Element
    end

    def reload
      if element.respond_to? :reload
        element.reload
      end
      self
    end

    protected

    def after_initialize
    end
  end
end
