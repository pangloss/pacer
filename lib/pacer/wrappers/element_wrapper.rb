module Pacer::Wrappers
  class ElementWrapper
    include Pacer::Element
    extend Forwardable
    include Comparable

    class << self
      def wrap(element, exts)
        wrapper_for(exts).new(element.element)
      end

      def extensions
        @extensions ||= []
      end

      def clear_cache
        Pacer.send :remove_const, :Wrap if Pacer.const_defined? :Wrap
        VertexWrapper.clear_cache
        EdgeWrapper.clear_cache
      end

      def route_conditions
        return @route_conditions if defined? @route_conditions
        @route_conditions = extensions.inject({}) do |h, ext|
          if ext.respond_to? :route_conditions
            h.merge! ext.route_conditions
          else
            h
          end
        end
        @route_conditions
      end

      protected

      def build_extension_wrapper(exts, mod_names, superclass)
        sc_name = superclass.to_s.split(/::/).last
        exts = exts.uniq unless exts.is_a? Set
        classname = "#{sc_name}#{exts.map { |m| m.to_s }.join('')}".gsub(/::/, '_').gsub(/\W/, '')
        eval "module ::Pacer; module Wrap; class #{classname.to_s} < #{sc_name}; end; end; end"
        wrapper = Pacer::Wrap.const_get classname
        exts.each do |obj|
          if obj.is_a? Module or obj.is_a? Class
            mod_names.each do |mod_name|
              if obj.const_defined? mod_name
                wrapper.send :include, obj.const_get(mod_name)
                wrapper.extensions << obj unless wrapper.extensions.include? obj
              end
            end
          end
        end
        wrapper
      end
    end

    attr_accessor :graph

    def initialize(element)
      @element = element
      after_initialize
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

    protected

    def after_initialize
    end
  end
end
