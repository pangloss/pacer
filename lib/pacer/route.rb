[Pacer::Core::Route, Pacer::ElementMixin, Pacer::Wrappers::EdgeWrapper, Pacer::Wrappers::VertexWrapper].each do |klass|
  klass.class_eval %{
    def chain_route(args_hash)
      Pacer::Route.new({ :back => self }.merge(args_hash))
    end
  }
end

module Pacer
  # The base class for almost everything in Pacer. Every route is an
  # instance of this class with a variety of modules mixed into the
  # instance at runtime.
  #
  # The class definition only contains methods directly related to the
  # construction of new Routes. For methods more likely to be used, see
  # the {Core::Route} module which is always mixed into this class.
  #
  # @see Core::Route
  class Route
    # @private
    module Helpers
      class << self
        def clear_cache
          @lookup_path = nil
        end

        def function(args)
          lookup_path.each do |key, map, extension|
            if value = args[key]
              function = map.fetch(value, value.is_a?(Module) && value)
              return [function, extension] if function
            end
          end
          nil
        end

        def lookup_path
          @lookup_path ||= [
            [:filter, filter_map, nil],
            [:transform, transform_map, nil],
            [:side_effect, side_effect_map, Pacer::Core::SideEffect]
          ]
        end

        def filter_map
          Hash[Pacer::Filter.constants.map { |name| [symbolize_module_name(name), Pacer::Filter.const_get(name)] }]
        end

        def side_effect_map
          Hash[Pacer::SideEffect.constants.map { |name| [symbolize_module_name(name), Pacer::SideEffect.const_get(name)] }]
        end

        def transform_map
          Hash[Pacer::Transform.constants.map { |name| [symbolize_module_name(name), Pacer::Transform.const_get(name)] }]
        end

        def symbolize_module_name(name)
          name.to_s.sub(/(Filter|SideEffect|Transform)$/, '').gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
        end
      end
    end

    class << self
      # A pipeline is sometimes required if a pipe needs to be passed
      # into a method that will change the starts on the same object
      # that it requests the next result from.
      #
      # @param [Route] route the route to create a pipeline based on
      # @return [Pacer::Pipes::BlackboxPipeline] an instantiated pipeline
      def pipeline(route)
        s, e = route.send(:build_pipeline)
        if s.equal?(e)
          s
        else
          Pacer::Pipes::BlackboxPipeline.new s, e
        end
      end
    end

    include Pacer::Core::Route
    include Pacer::Routes::RouteOperations

    # The function mixed into this instance
    attr_reader :function

    # The type of object that this route emits.
    attr_reader :element_type

    # Additional info to include after the class name when generating a
    # name for this route.
    attr_accessor :info

    # The previous route in the chain
    attr_reader :back

    # The soure of data for the entire chain. Routes that have a source
    # generally should not have a {#back}
    attr_reader :source

    # Create a new route. It should be very rare that you would need to
    # directly create a Route object.
    #
    # See {Core::Graph::GraphRoute} and {GraphMixin} for methods
    # to build routes based on a graph.
    #
    # See {ElementMixin}, {VertexMixin} and
    # {EdgeMixin} for methods to build routes based on an
    # individual graph element.
    #
    # @see Core::Graph::GraphRoute
    # @see GraphMixin
    # @see ElementMixin
    # @see VertexMixin
    # @see EdgeMixin
    #
    # See Pacer's {Enumerable#to_route} method to create a route based
    # on an Array, a Set or any other Enumerable type.
    #
    # @param [Hash] args
    # @option args [Graph] :graph the graph this route is based on
    # @option args [Route] :bace the previous route in the chain
    # @option args [element type] :element_type
    # @option args [Module] :modules additional modules to mix in
    # @option args [Symbol, Module] :filter the filter to use as this
    #   route's function
    # @option args [Symbol, Module] :side_effect the side effect to use
    #   as this route's function (Also triggers the {Core::SideEffect}
    #   mixin)
    # @option args [Symbol, Module] :transform the transform module to
    #   use as this route's function
    # @option args [[Module]] :extensions extensions for this route
    #
    # All other keys sent to the args method will be converted into
    # setter method calls and called against the instantiated route to
    # allow modules to define their own setup however they need.
    #
    # @example If a route is constructed with the a custom key:
    #   route = Route.new(:filter => :block, :block => proc { |element| element.element_id.even? })
    #
    #   # is theoretically the same as
    #
    #   route = Route.new
    #   route.extend Pacer::Filter::BlockFilter
    #   route.block = proc { |element| element.element_id.even? }
    #   route
    #
    # When the route object is fully initialized, the
    # {#after_initialize} method is called to allow mixins to do any
    # additional setup.
    def initialize(args = {})
      @@graph = @back = @source = nil
      @wrapper = nil
      @extensions = Set[]
      self.graph = args[:graph]
      self.back = args[:back]
      include_function args
      set_element_type args
      include_other_modules args
      keys = args.keys - [:element_type, :modules, :graph, :back, :filter, :side_effect, :transform]
      keys.each do |key|
        send("#{key}=", args[key])
      end
      include_extensions args
      after_initialize
    rescue Exception => e
      puts "Exception creating Route with #{ args.inspect }" if Pacer.verbose?
      raise
    end

    # Set the element type of this route and include the apropriate
    # mixin to support the element type.
    #
    # TODO should this method be protected?
    #
    # @param [:vertex, :edge, :mixed, element type, Object] et the
    #   element type to use
    def element_type=(et)
      if graph
        @element_type = graph.element_type(et)
        if @element_type == graph.element_type(:vertex)
          extend Pacer::Core::Graph::VerticesRoute
        elsif @element_type == graph.element_type(:edge)
          extend Pacer::Core::Graph::EdgesRoute
        elsif @element_type == graph.element_type(:mixed)
          extend Pacer::Core::Graph::MixedRoute
        end
      elsif et == :object or et == Object
        @element_type = Object
      else
        raise "Element type #{ et.inspect } specified, but no graph specified."
      end
    end

    protected

    # This callback may be overridden. Be sure to call super() though.
    # @return ignored
    def after_initialize
    end

    # Find the module for the function to include based on the :filter,
    # :side_effect or :transform argument given to {#initialize} and
    # extend this instance with it.
    def include_function(args)
      @function, extension = Route::Helpers.function(args)
      self.extend extension if extension
      self.extend function if function
    end

    # @return [Route, nil] the previous route in the chain
    def back_object(args)
      back || args[:back]
    end

    # Get element type from the previous route in the chain.
    # @return [element type, nil]
    def back_element_type(args)
      b = back_object(args)
      if b.respond_to? :element_type
        b.element_type
      end
    end

    # If no element type has been specified, try to find one from
    # the previous route in the chain.
    # @raise [StandardError] if no element type can be found
    def set_element_type(args)
      if args[:element_type]
        self.element_type = args[:element_type]
      else
        if bet = back_element_type(args)
          self.element_type = bet
        else
          raise "No element_type specified or inferred"
        end
      end
    end

    # extends this class with any modules passed to {#initialize} in the
    # :modules key.
    def include_other_modules(args)
      if mods = args[:modules]
        @modules = [*mods]
        @modules.each do |mod|
          extend mod
        end
      end
    end

    # Copy extensions from the previous route in the chain if the
    # previous route's element type is the same as the current route's
    # element type and no extensions were explicitly set on this route.
    def include_extensions(args)
      if back_element_type(args) == self.element_type and not args.key? :extensions and not args.key? :wrapper
        back_obj = back_object(args)
        if not wrapper and extensions.none?
          self.wrapper = back_obj.wrapper if back_obj.respond_to? :wrapper
          self.extensions = back_obj.extensions if back_obj.respond_to? :extensions
        end
      end
    end

    # Creates a terse, human-friendly name for the class based on its
    # element type, function and info.
    # @return [String]
    def inspect_class_name
      s = "#{element_type.to_s.scan(/Elem|Obj|V|E/).last}"
      s = "#{s}-#{function.name.split('::').last.sub(/Filter|Route$/, '')}" if function
      s = "#{s} #{ @info }" if @info
      s
    end
  end
end
