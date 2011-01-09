module Pacer::Routes
  module Base
    def chain_route(args_hash)
      FilterRoute.new(args_hash)
    end
  end

  class FilterRoute
    include Base
    include RouteOperations

    def initialize(args = {})
      args = Hash[args]
      extend module_for_args(args)
      args.each do |key, value|
        send("#{key}=", value)
      end
      unless args.key? :element_type
        if back
          self.element_type = back.element_type
        else
          raise "No element_type specified"
        end
      end
    end

    def source=(source)
      self.back = source
    end

    def back=(back)
      if back.is_a? Base
        @back = back
      else
        @source = back
      end
    end

    def element_type=(et)
      @element_type = graph.element_type(et)
      if @element_type == graph.element_type(:vertex)
        extend VerticesRouteModule
      elsif @element_type == graph.element_type(:vertex)
        extend EdgesRouteModule
      elsif @element_type == graph.element_type(:vertex)
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

    def module_for_args(args)
      filter = args.delete(:filter)
      if filter
        if filter.is_a? Module
          return filter
        else
          case filter
          when Symbol, String
            mod_name = filter_map[fm.to_sym]
            return Pacer::Filter.const_get(mod) if mod
          end
        end
      else
        args.each_key do |key|
          mod = trigger_map[key]
          return mod if mod
        end
      end
      raise "No module found for #{ fm.inspect }"
    end

    def filter_map
      @filter_map ||= Pacer::Filter.constants.group_by { |name| symbolize_filter_name(name) }
    end

    def trigger_map
      return @trigger_map if @trigger_map
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
