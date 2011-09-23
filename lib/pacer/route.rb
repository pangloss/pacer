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
    # TODO The logic for filter, side_effect and transform is so simillar.
    # Make it DRY
    #
    # TODO Is the trigger stuff worthwhile?
    module Helpers
      class << self
        def clear_cache
          @filter_map = nil
          @trigger_map = nil
          @side_effect_map = nil
          @transform_map = nil
        end

        def filter_map
          @filter_map ||= Pacer::Filter.constants.group_by { |name| symbolize_module_name(name) }
        end

        def side_effect_map
          @side_effect_map ||= Pacer::SideEffect.constants.group_by { |name| symbolize_module_name(name) }
        end

        def transform_map
          @transform_map ||= Pacer::Transform.constants.group_by { |name| symbolize_module_name(name) }
        end

        def trigger_map
          return @trigger_map if @trigger_map
          @trigger_map = {}
          [Pacer::Filter, Pacer::SideEffect, Pacer::Transform].each do |base_module|
            base_module.constants.each do |name|
              mod = base_module.const_get(name)
              if mod.respond_to? :triggers
                [*mod.triggers].each do |trigger|
                  @trigger_map[trigger] = mod
                end
              end
            end
          end
          @trigger_map
        end

        def symbolize_module_name(name)
          name.to_s.sub(/(Filter|SideEffect|Transform)$/, '').gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
        end
      end
    end

    class << self
      # This method is useful for creating sideline routes that branch
      # off of the current route.
      #
      # It creates a new route without any source based on the type,
      # filters, function and extensions of the given route. The main
      # thing about the returned route is that the pipeline that is
      # built from it will not include any of the pipes that make up
      # the route it's based on.
      #
      # @param [Route] back the route the new route is based on.
      # @return [Route]
      def empty(back)
        Pacer::Route.new :filter => :empty, :back => back
      end

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
      @each_method = nil
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
        else
          @each_method = :each_object
        end
      elsif et == :object or et == Object
        @element_type = Object
        @each_method = :each_object
      else
        raise "Element type #{ et.inspect } specified, but no graph specified."
      end
    end

    # Iterate over all elements emitted from this route.
    #
    # @yield [element] the emitted element
    # @return [Enumerator] only if no block is given.
    def each(&block)
      if @each_method
        send(@each_method, &block)
      else
        each_element(&block)
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
      if args[:side_effect]
        extend Pacer::Core::SideEffect
      end
      filter = args[:filter]
      side_effect = args[:side_effect]
      transform = args[:transform]
      if filter.is_a? Module
        @function = filter
      elsif filter.is_a? Symbol
        mod_names = Route::Helpers.filter_map[filter.to_sym]
        if mod_names
          @function = Pacer::Filter.const_get(mod_names.first)
        end
      elsif side_effect.is_a? Module
        @function = side_effect
      elsif side_effect.is_a? Symbol
        mod_names = Route::Helpers.side_effect_map[side_effect.to_sym]
        if mod_names
          @function = Pacer::SideEffect.const_get(mod_names.first)
        end
      elsif transform.is_a? Module
        @function = transform
      elsif transform.is_a? Symbol
        mod_names = Route::Helpers.transform_map[transform.to_sym]
        if mod_names
          @function = Pacer::Transform.const_get(mod_names.first)
        end
      else
        args.each_key do |key|
          mod = Route::Helpers.trigger_map[key]
          if mod
            @function = mod
            break
          end
        end
      end
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
