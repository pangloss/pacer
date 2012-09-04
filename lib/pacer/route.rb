[Pacer::Core::Route, Pacer::Wrappers::ElementWrapper, Pacer::Wrappers::EdgeWrapper, Pacer::Wrappers::VertexWrapper].each do |klass|
  klass.class_eval %{
    def chain_route(args_hash)
      Pacer::RouteBuilder.current.chain self, args_hash
    end
  }
end

module Pacer

  class RouteBuilder
    class << self
      attr_writer :current

      def current
        @current ||= RouteBuilder.new
      end
    end

    attr_reader :types

    def initialize
      @types = Hash.new do |h, type_def|
        h[type_def] = Class.new(Route) do
          type_def.each do |mods|
            mods.each do |mod|
              include mod
            end
          end
        end
      end
    end

    def chain(source, args)
      types[type_def(source, args)].new source, configuration(source, args), arguments(source, args)
    end

    protected

    def source_value(source, name)
      source.send name if source.respond_to? name
    end

    def type_def(source, args)
      [
        type_modules(source, args),
        function_modules(source, args),
        other_modules(source, args),
        extension_modules(source, args)
      ]
    end

    def configuration(source, args)
      {
        element_type: element_type(source, args),
        graph: graph(source, args),
        extensions: extensions(source, args),
        wrapper: wrapper(source, args),
        function: function_modules(source, args).first
      }
    end

    def arguments(source, args)
      args.reject do |key, val|
        Set[:element_type, :wrapper, :extensions, :modules, :graph, :back, :filter, :side_effect, :transform, :visitor].include? key
      end
    end

    def graph(source, args)
      args[:graph] || source_value(source, :graph)
    end

    def element_type(source, args)
      et = args[:element_type] || source_value(source, :element_type)
      if not et
        fail ClientError, "No element_type specified or inferred"
      end
      if not graph(source, args) and (et == :vertex or et == :edge or et == :mixed)
        fail ClientError, "Element type #{ et.inspect } specified, but no graph specified."
      end
      et
    end

    def type_modules(source, args)
      case element_type source, args
      when :vertex
        [Pacer::Core::Graph::ElementRoute, Pacer::Core::Graph::VerticesRoute]
      when :edge
        [Pacer::Core::Graph::ElementRoute, Pacer::Core::Graph::EdgesRoute]
      when :mixed
        [Pacer::Core::Graph::ElementRoute, Pacer::Core::Graph::MixedRoute]
      else
        []
      end
    end

    def other_modules(source, args)
      [*args[:modules]]
    end

    def type_from_source?(source, args)
      element_type(source, args) == source_value(source, :element_type)
    end

    def wrapper(source, args)
      args.fetch(:wrapper) do
        source_value(source, :wrapper) if type_from_source? source, args
      end
    end

    def extensions(source, args)
      exts = args.fetch(:extensions) do
        source_value(source, :extensions) if type_from_source? source, args
      end
      if exts.is_a? Set
        exts.to_a
      elsif exts.is_a? Module
        [exts]
      elsif exts.is_a? Array
        exts.uniq
      else
        []
      end
    end

    def all_extensions(source, args)
      w = wrapper source, args
      exts = extensions source, args
      if w and exts
        (w.extensions + exts).uniq
      elsif w
        w.extensions
      elsif exts
        exts
      else
        []
      end
    end

    def extension_modules(source, args)
      all_extensions(source, args).uniq.select do |mod|
        mod.respond_to?(:const_defined?) and mod.const_defined? :Route
      end.map { |mod| mod::Route }
    end


    def function_modules(source, args)
      FunctionResolver.function(args).compact
    end
  end


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

    def wrapper
      config[:wrapper]
    end

    def extensions
      config[:extensions]
    end

    def all_extensions
      if wrapper
        (wrapper.extensions + extensions).uniq
      else
        extensions
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
