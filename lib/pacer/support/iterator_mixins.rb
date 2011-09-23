module Pacer::Core::Route
  # This mixin allows an iterator to be returned from methods that perform a
  # transformation on the elements in their collection. Set the block property
  # to the proc that does the transformation.
  module IteratorBlockMixin
    attr_accessor :graph

    # Set the block that does the transformation.
    def block=(block)
      @block = block
    end

    def next
      item = super
      item.graph ||= @graph
      @block.call(item)
    end
  end

  module IteratorContextMixin
    attr_accessor :graph

    # Set the context
    def context=(context)
      @context = context
    end

    def next
      item = super
      item.back = @context
      item.graph ||= @graph
      item
    end
  end

  module IteratorPathMixin
    attr_accessor :graph

    def next
      super
      path.collect do |e|
        e.graph ||= @graph if e.respond_to? :graph=
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
    attr_reader :graph, :wrapper

    def wrapper=(w)
      @wrapper = w
      @set_graph = set_graph?
    end

    def graph=(g)
      @graph = g
      @set_graph = set_graph?
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
      item.graph = graph if @set_graph
      item
    end
  end

  module IteratorMixin
    attr_accessor :graph

    def next
      item = super
      if item.respond_to? :graph=
        item.graph ||= @graph
      end
      item
    end
  end
end
