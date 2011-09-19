module Pacer::Wrappers
  class ElementWrapper
    extend Forwardable

    class << self
      def wrap(element, exts)
        wrapper_for(exts.to_set).new(element.element)
      end

      def extensions
        @extensions ||= Set[]
      end

      def clear_cache
        Pacer.send :remove_const, :Wrap if Pacer.const_defined? :Wrap
        @wrappers = {}
      end

      protected

      def build_extension_wrapper(exts, mod_names, superclass)
        sc_name = superclass.to_s.split(/::/).last
        classname = "#{sc_name}#{exts.map { |m| m.to_s }.join('')}".gsub(/::/, '_').gsub(/\W/, '')
        eval "module ::Pacer; module Wrap; class #{classname.to_s} < #{sc_name}; end; end; end"
        wrapper = Pacer::Wrap.const_get classname
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

    protected

    def _swap_element!(element)
      @element = element
    end

    def after_initialize
    end
  end
end
