[Pacer::Core::Route, Pacer::ElementMixin, Pacer::EdgeWrapper, Pacer::VertexWrapper].each do |klass|
  klass.class_eval %{
    def chain_route(args_hash)
      Pacer::Route.new({ :back => self }.merge(args_hash))
    end
  }
end

module Pacer
  class Route
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
      def empty(back)
        Pacer::Route.new :filter => :empty, :back => back
      end
    end

    include Pacer::Core::Route
    include Pacer::Routes::RouteOperations

    def initialize(args = {})
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

    # This callback may be overridden. Be sure to call super() though.
    def after_initialize
    end

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
      extend @function if @function
    end

    def back_object(args)
      back || args[:back]
    end

    def back_element_type(args)
      if back.respond_to? :element_type
        back.element_type
      elsif args[:back].respond_to? :element_type
        args[:back].element_type rescue nil
      end
    end

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

    def include_other_modules(args)
      if mods = args[:modules]
        @modules = [*mods]
        @modules.each do |mod|
          extend mod
        end
      end
    end

    def include_extensions(args)
      if back_element_type(args) == self.element_type and not args.key? :extensions
        self.extensions = back_object(args).extensions if back_object(args).respond_to? :extensions
      end
    end

    def inspect_class_name
      s = "#{element_type.to_s.scan(/Elem|Obj|V|E/).last}"
      s = "#{s}-#{@function.name.split('::').last.sub(/Filter|Route$/, '')}" if @function
      s = "#{s} #{ @info }" if @info
      s
    end
  end
end
