module Pacer::Core::Route
  class WrapperSelector
    import com.tinkerpop.blueprints.Vertex
    import com.tinkerpop.blueprints.Edge

    def self.build(element_type)
      if element_type == :vertex
        Pacer::Wrappers::VertexWrapper
      elsif element_type == :edge
        Pacer::Wrappers::EdgeWrapper
      else
        new
      end
    end

    def new(element)
      if element.is_a? Vertex
        Pacer::Wrappers::VertexWrapper.new element
      elsif element.is_a? Edge
        Pacer::Wrappers::EdgeWrapper.new element
      else
        element
      end
    end
  end


  # This mixin allows an iterator to be returned from methods that perform a
  # transformation on the elements in their collection. Set the block property
  # to the proc that does the transformation.
  module IteratorBlockMixin
    attr_reader :graph, :wrapper, :element_type
    attr_reader :block

    def element_type=(element_type)
      @wrapper = WrapperSelector.build element_type
    end

    def graph=(g)
      @graph = g
      @wrapper ||= WrapperSelector.new
    end

    # Set the block that does the transformation.
    def block=(block)
      @block = block
    end

    def next
      item = wrapper.new super
      item.graph = graph
      block.call(item)
    end
  end

  module IteratorPathMixin
    attr_reader :graph, :wrapper

    def graph=(g)
      @graph = g
      @wrapper = WrapperSelector.new
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
    attr_accessor :graph, :extensions

    def next
      item = super
      # TODO: optimize this (and other) check:
      #   - exception?
      #   - type check?
      #   - method check?
      #   - ...?
      if item.respond_to? :graph=
        item = item.add_extensions @extensions
        item.graph ||= @graph
      end
      item
    end
  end

  module IteratorWrapperMixin
    attr_reader :graph, :extensions, :wrapper

    def wrapper=(w)
      @base_wrapper = w
      @wrapper = build_wrapper?
      @set_graph = set_graph?
    end

    def graph=(g)
      @graph = g
      @wrapper = build_wrapper?
      @set_graph = set_graph?
    end

    def extensions=(exts)
      @extensions = exts
      @wrapper = build_wrapper?
      @set_graph = set_graph?
    end

    def build_wrapper?
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

    def next
      item = wrapper.new(super)
      item.graph ||= graph if @set_graph
      item
    end
  end

  module IteratorMixin
    attr_reader :graph, :wrapper

    def element_type=(element_type)
      @wrapper = WrapperSelector.build element_type
    end

    def graph=(g)
      @graph = g
      @wrapper ||= WrapperSelector.new
    end

    def next
      item = wrapper.new super
      item.graph = graph
      item
    end
  end
end
