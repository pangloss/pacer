require 'forwardable'

module Pacer
  class ElementWrapper
    extend Forwardable

    class << self
      def wrap(element, exts)
        wrapper_for(exts).new(element)
      end

      def extensions
        @extensions ||= Set[]
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

    def initialize(element)
      @element = element
    end

    def_delegators :@element, :get_id,
      :property_keys, :get_property, :set_property, :remove_property,
      :out_edges, :in_edges, :out_vertices, :in_vertices,
      :raw_vertex, :raw_edge,
      :label

    def element
      @element
    end
  end

  class EdgeWrapper < ElementWrapper
    include Pacer::Routes::EdgesRouteModule
    include ElementMixin
    include EdgeMixin

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
  end

  class VertexWrapper < ElementWrapper
    include Pacer::Routes::VerticesRouteModule
    include ElementMixin
    include VertexMixin

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
  end
end
