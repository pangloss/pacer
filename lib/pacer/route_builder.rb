module Pacer
  class RouteBuilder
    REJECT_KEYS = Set[:element_type, :wrapper, :extensions, :modules, :graph,
                      :back, :filter, :side_effect, :transform, :visitor,
                      :based_on]

    class << self
      attr_writer :current

      def current
        @current ||= RouteBuilder.new
      end
    end

    attr_reader :types, :element_types

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

      @element_types = Hash.new { |h, k| h[k] = [] }
      element_types[:vertex] = [Pacer::Core::Graph::ElementRoute, Pacer::Core::Graph::VerticesRoute]
      element_types[:edge] = [Pacer::Core::Graph::ElementRoute, Pacer::Core::Graph::EdgesRoute]
      element_types[:mixed] = [Pacer::Core::Graph::ElementRoute, Pacer::Core::Graph::MixedRoute]
      element_types[:path] = [Pacer::Core::ArrayRoute, Pacer::Core::Graph::PathRoute]
      element_types[:string] = [Pacer::Core::StringRoute]
      element_types[:array] = [Pacer::Core::ArrayRoute]
      element_types[:hash] = [Pacer::Core::HashRoute]
    end

    def chain(source, args)
      types[type_def(source, args)].new source, configuration(source, args), arguments(source, args)
    end

    protected

    def source_value(source, name)
      source.send name if source.respond_to? name
    end

    def type_def(source, args)
      source = args.fetch(:based_on, source)
      [
        type_modules(source, args),
        function_modules(source, args),
        other_modules(source, args),
        extension_modules(source, args)
      ]
    end

    def configuration(source, args)
      source = args.fetch(:based_on, source)
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
        REJECT_KEYS.include? key
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
      element_types[element_type source, args]
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
end
