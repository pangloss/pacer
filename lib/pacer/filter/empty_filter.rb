module Pacer
  module Filter
    module EmptyFilter
      protected

      def after_initialize
        @back = @source = nil
        super
      end

      def build_pipeline
        nil
      end

      def inspect_class_name
        s = "#{element_type.to_s.scan(/Elem|Obj|V|E/).last}"
        s = "#{s} #{ @info }" if @info
        s
      end
    end
  end
end
