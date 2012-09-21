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

    attr_reader :config

    # The wrapper object to use to wrap elements in.
    #
    # If it responds to #add_extensions and the rout also has additional
    # extensions, it will be used to generate a new wrapper dynamically.
    def wrapper
      config[:wrapper]
    end

    # Get the set of extensions currently on this route.
    #
    # The order of extensions for custom defined wrappers are
    # guaranteed. If a wrapper is iterated with additional extensions,
    # a new wrapper will be created dynamically with the original
    # extensions in order followed by any additional extensions in
    # undefined order.
    #
    # Returns an Array
    #
    # @return [Array[extension]]
    def extensions
      if wrapper
        (wrapper.extensions + config[:extensions]).uniq
      else
        config[:extensions]
      end
    end

    # The type of object that this route emits.
    def element_type
      config[:element_type]
    end

    # The function mixed into this instance
    def function
      config[:function]
    end

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
    # See {Core::Graph::GraphRoute} and {PacerGraph} for methods
    # to build routes based on a graph.
    #
    # See {ElementWrapper}, {VertexWrapper} and
    # {EdgeWrapper} for methods to build routes based on an
    # individual graph element.
    #
    # @see Core::Graph::GraphRoute
    # @see PacerGraph
    # @see ElementWrapper
    # @see VertexWrapper
    # @see EdgeWrapper
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
    def initialize(source, config, args)
      if source.is_a? Route
        @back = source
      else
        @source = source
      end
      @config = config
      @args = args

      args.each do |key, value|
        send("#{key}=", value)
      end

      after_initialize
    rescue Exception => e
      begin
        if Pacer.verbose?
          puts "Exception #{ e.class } #{ e.message } ..."
          puts "... creating #{ config.inspect } route"
          puts "... with #{ args.inspect }"
        end
      rescue Exception
      end
      raise e
    end

    protected

    # This callback may be overridden. Be sure to call super() though.
    # @return ignored
    def after_initialize
    end
  end
end
