module Pacer::Core
  module Route
    def chain_route(args_hash)
      FilterRoute.new(args_hash)
    end
  end
end

module Pacer::Routes
  class NoFilterSpecified < RuntimeError
  end

  class FilterRoute
    module Helpers
      class << self
        def filter_map
          @filter_map = Pacer::Filter.constants.group_by { |name| symbolize_filter_name(name) }
        end

        def trigger_map
          #return @trigger_map if @trigger_map
          @trigger_map = {}
          Pacer::Filter.constants.each do |name|
            mod = Pacer::Filter.const_get(name)
            if mod.respond_to? :triggers
              [*mod.triggers].each do |trigger|
                @trigger_map[trigger] = mod
              end
            end
          end
          @trigger_map
        end

        def symbolize_filter_name(name)
          name.sub(/Filter$/, '').gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase.to_sym
        end
      end
    end

    include Pacer::Core::Route
    include RouteOperations

    def initialize(args = {})
      args = args.dup
      element_type = args.delete(:element_type)
      @filter = module_for_args(args)
      extend @filter
      args.each do |key, value|
        send("#{key}=", value)
      end
      if back.respond_to? :element_type
        back_object = back
        back_element_type = back.element_type
      elsif args[:back].respond_to? :element_type
        back_object = args[:back]
        back_element_type = args[:back].element_type
      end
      back_element_type
      if element_type
        self.element_type = element_type
      elsif back_element_type
        self.element_type = back_element_type
      else
        raise NoFilterSpecified, "No element_type specified"
      end
      if back_element_type == self.element_type and not args.key? :extensions
        self.extensions = back_object.extensions if back_object.respond_to? :extensions
      end
      after_initialize
    end

    def element_type=(et)
      @element_type = graph.element_type(et)
      if @element_type == graph.element_type(:vertex)
        extend VerticesRouteModule
      elsif @element_type == graph.element_type(:edge)
        extend Pacer::Core::Graph::EdgesRoute
      elsif @element_type == graph.element_type(:mixed)
        extend MixedRouteModule
      else
        @each_method = :each_object
      end
    end

    def each(&block)
      if @each_method
        send(@each_method, &block)
      else
        each_element(&block)
      end
    end

    def element_type
      @element_type
    end

    protected

    def after_initialize
    end

    def module_for_args(args)
      filter = args[:filter]
      if filter
        if filter.is_a? Module
          return filter
        else
          case filter
          when Symbol, String
            mod_names = FilterRoute::Helpers.filter_map[filter.to_sym]
            if mod_names
              args.delete :filter
              return Pacer::Filter.const_get(mod_names.first)
            end
          end
        end
      else
        args.each_key do |key|
          mod = FilterRoute::Helpers.trigger_map[key]
          return mod if mod
        end
      end
      raise NoFilterSpecified, "No module found for #{ args.inspect }"
    end

    def inspect_class_name
      s = "#{element_type.to_s.scan(/Elem|Obj|V|E/).last}-#{@filter.name.split('::').last.sub(/Filter|Route$/, '')}"
      s = "#{s} #{ @info }" if @info
      s
    end
  end
end
