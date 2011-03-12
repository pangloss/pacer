require 'forwardable'

module Pacer
  def self.vertex_wrapper(*exts)
    VertexWrapper.wrapper_for(exts)
  end

  def self.edge_wrapper(*exts)
    EdgeWrapper.wrapper_for(exts)
  end

  class NewElement
    def initialize
      @properties = {}
      @out_edges = []
      @in_edges = []
    end

    def get_id
      nil
    end

    def property_keys
      @properties.keys
    end

    def get_property(prop)
      @properties[prop]
    end

    def set_property(prop, value)
      @properties[prop] = value
    end

    def remove_property(prop)
      @properties.delete prop
    end

    def out_edges
      @out_edges
    end

    def in_edges
      @in_edges
    end

    def raw_vertex
      self
    end

    def graph
      @graph
    end

    def graph=(graph)
      @graph = graph
    end

    def <=>(other)
      -1
    end

    def ==(other)
      equal? other
    end
  end

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
        Pacer.send :remove_const, :Wrappers if Pacer.const_defined? :Wrappers
        @wrappers = nil
      end

      protected

      def build_extension_wrapper(exts, mod_names, superclass)
        sc_name = superclass.to_s.split(/::/).last
        classname = "#{sc_name}#{exts.map { |m| m.to_s }.join('')}".gsub(/::/, '_').gsub(/\W/, '')
        eval "module ::Pacer; module Wrappers; class #{classname.to_s} < #{sc_name}; end; end; end"
        wrapper = Pacer::Wrappers.const_get classname
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

    def hash
      @element.hash
    end

    def eql?(other)
      @element.eql?(other)
    end

    def initialize(element = nil)
      @element = element || NewElement.new
      after_initialize
    end

    protected

    def _swap_element!(element)
      @element = element
    end

    def after_initialize
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
      def wrapper_for(exts)
        @wrappers ||= {}
        @wrappers[exts] ||= build_edge_wrapper(exts)
      end

      protected

      def build_edge_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Edge], EdgeWrapper)
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
      def wrapper_for(exts)
        @wrappers ||= {}
        @wrappers[exts] ||= build_vertex_wrapper(exts)
      end

      protected

      def build_vertex_wrapper(exts)
        build_extension_wrapper(exts, [:Route, :Vertex], VertexWrapper)
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
