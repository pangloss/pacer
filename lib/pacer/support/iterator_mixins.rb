module Pacer::Core::Route
  module IteratorPathMixin
    attr_reader :graph, :wrapper

    def graph=(g)
      @graph = g
      @wrapper = Pacer::Wrappers::WrapperSelector.build
    end

    def next
      super.collect do |e|
        e = wrapper.new e
        e.graph = graph if e.respond_to? :graph=
        e
      end
    end
  end

  module IteratorExtensionsMixin
    attr_reader :graph, :wrapper, :extensions, :element_type

    def element_type=(element_type)
      @element_type = element_type
      build_wrapper
    end

    def graph=(g)
      @graph = g
      build_wrapper
    end

    def extensions=(e)
      @extensions = e
      build_wrapper
    end

    def next
      item = wrapper.new super
      if item.respond_to? :graph=
        item.graph = @graph
      end
      item
    end

    private

    def build_wrapper
      @wrapper = Pacer::Wrappers::WrapperSelector.build element_type, extensions
    end
  end

  module IteratorWrapperMixin
    attr_reader :graph, :extensions, :wrapper

    def wrapper=(w)
      @base_wrapper = w
      @wrapper = build_wrapper
      @set_graph = set_graph?
    end

    def graph=(g)
      @graph = g
      @wrapper = build_wrapper
      @set_graph = set_graph?
    end

    def extensions=(exts)
      @extensions = exts
      @wrapper = build_wrapper
      @set_graph = set_graph?
    end

    def next
      item = wrapper.new(super)
      item.graph ||= graph if @set_graph
      item
    end

    private

    def build_wrapper
      @base_wrapper = nil unless defined? @base_wrapper
      @extensions = nil unless defined? @extensions
      if @base_wrapper and @extensions
        @wrapper = @base_wrapper.wrapper_for(@base_wrapper.extensions + @extensions.to_a)
      elsif @base_wrapper
        @wrapper = @base_wrapper
      elsif @extensions
        # FIXME: use WrapperSelector here + the extensions?
        # ... We don't know what type of wrapper to create
      end
    end

    if RUBY_VERSION =~ /^1\.8\./
      def set_graph?
        graph and wrapper and wrapper.instance_methods.include?('graph=')
      end
    else
      def set_graph?
        graph and wrapper and wrapper.instance_methods.include?(:graph=)
      end
    end

  end

  module IteratorMixin
    attr_reader :graph, :wrapper

    def element_type=(element_type)
      @wrapper = Pacer::Wrappers::WrapperSelector.build element_type
    end

    def graph=(g)
      @graph = g
      @wrapper ||= Pacer::Wrappers::WrapperSelector.build
    end

    def next
      item = wrapper.new super
      item.graph = graph if item.respond_to? :graph=
      item
    end
  end
end
