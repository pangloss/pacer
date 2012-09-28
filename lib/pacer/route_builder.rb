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
      when :path
        [Pacer::Core::Graph::PathRoute]
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
end
