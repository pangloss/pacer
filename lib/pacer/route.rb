[Pacer::Core::Route, Pacer::ElementMixin, Pacer::EdgeWrapper, Pacer::VertexWrapper].each do |klass|
  klass.class_eval %{
    def chain_route(args_hash)
      Pacer::Route.new({ :back => self }.merge(args_hash))
    end
  }
end

module Pacer::ElementMixin
  def chain_route(args_hash)
    Pacer::Route.new({ :back => self }.merge(args_hash))
  end
end

module Pacer
  class NoFilterSpecified < RuntimeError
  end

  class Route
    module Helpers
      class << self
        def clear_cache
          @filter_map = nil
          @trigger_map = nil
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

    include Pacer::Core::Route
    include Pacer::Routes::RouteOperations

    def initialize(args = {})
      self.graph = args[:graph]
      self.back = args[:back]
      include_filter args
      set_element_type args
      include_other_modules args
      keys = args.keys - [:element_type, :modules, :graph, :back, :filter]
      keys.each do |key|
        send("#{key}=", args[key])
      end
      include_extensions args
      after_initialize
    rescue => e
      puts "Exception creating Route with #{ args.inspect }" if Pacer.verbose?
      raise
    end

    def element_type=(et)
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

    def include_filter(args)
      filter = args[:filter]
      if filter
        if filter.is_a? Module
          return filter
        else
          case filter
          when Symbol, String
            mod_names = Route::Helpers.filter_map[filter.to_sym]
            if mod_names
              @filter = Pacer::Filter.const_get(mod_names.first)
            end
          end
        end
      else
        args.each_key do |key|
          mod = Route::Helpers.trigger_map[key]
          if mod
            @filter = mod
            break
          end
        end
      end
      extend @filter if @filter
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
          raise NoFilterSpecified, "No element_type specified or inferred"
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
      s = "#{s}-#{@filter.name.split('::').last.sub(/Filter|Route$/, '')}" if @filter
      s = "#{s} #{ @info }" if @info
      s
    end
  end
end
