require 'forwardable'

module Pacer
  class ElementWrapper
    extend Forwardable

    class << self
      def wrap(element, exts)
        wrapper_for(exts).new(element.element)
      end

      def extensions
        @extensions ||= Set[]
      end

      def clear_cache
        @wrappers = nil
      end

      protected

      def build_extension_wrapper(exts, mod_names)
        if block_given?
          wrapper = yield
        else
          wrapper = Class.new(ExtensionWrapper)
        end
        exts.each do |obj|
          if obj.is_a? Module or obj.is_a? Class
            mod_names.each do |mod_name|
              if obj.const_defined? mod_name
                wrapper.send :include, obj.const_get(mod_name)
                wrapper.extensions << obj
              end
            end
          end
        end
        wrapper
      end
    end

    def element_id
      @element.get_id
    end

    def initialize(element)
      @element = element
    end
  end

  class EdgeWrapper < ElementWrapper
    include Pacer::Core::Graph::EdgesRoute
    include ElementMixin
    include EdgeMixin
    include Comparable

    def_delegators :@element,
      :label, :get_label, :property_keys, :get_property, :set_property, :remove_property,
      :in_vertex, :out_vertex,
      :raw_edge,
      :graph, :graph=, :<=>, :==

    class << self
      protected

      def build_edge_wrapper(exts)
        wrapper = build_extension_wrapper(exts, [:Route, :Edge]) do
          Class.new EdgeWrapper
        end
      end

      def wrapper_for(exts)
        @wrappers ||= {}
        @wrappers[exts] ||= build_edge_wrapper(exts)
      end
    end

    def extensions
      self.class.extensions
    end

    def element
      @element
    end
  end

  class VertexWrapper < ElementWrapper
    include Pacer::Core::Graph::VerticesRoute
    include ElementMixin
    include VertexMixin
    include Comparable

    def_delegators :@element,
      :property_keys, :get_property, :set_property, :remove_property,
      :out_edges, :in_edges,
      :raw_vertex,
      :graph, :graph=, :<=>, :==

    class << self
      protected

      def build_vertex_wrapper(exts)
        wrapper = build_extension_wrapper(exts, [:Route, :Vertex]) do
          Class.new VertexWrapper
        end
      end

      def wrapper_for(exts)
        @wrappers ||= {}
        @wrappers[exts] ||= build_vertex_wrapper(exts)
      end
    end

    def extensions
      self.class.extensions
    end

    def element
      @element
    end
  end
end
