require 'pacer/filter/property_filter/filters'
require 'pacer/filter/property_filter/edge_filters'

module Pacer
  class Route
    class << self
      def property_filter_before(base, filters, block)
        if filters and filters.any? or block
          yield new(:back => base, :filter => :property, :filters => filters, :block => block)
        else
          yield base
        end
      end

      def property_filter(base, filters, block)
        if filters and filters.any? or block
          new(:back => base, :filter => :property, :filters => filters, :block => block)
        elsif Pacer.vertex? base
          new(:back => base, :pipe_class => Pacer::Pipes::IdentityPipe)
        elsif Pacer.edge? base
          new(:back => base, :pipe_class => Pacer::Pipes::IdentityPipe)
        else
          base
        end
      end
    end
  end

  module Filter
    module PropertyFilter
      import com.tinkerpop.pipes.pgm.LabelCollectionFilterPipe
      import com.tinkerpop.pipes.pgm.PropertyFilterPipe

      def self.triggers
        [:filters]
      end

      attr_accessor :block

      def filters=(f)
        @filters = EdgeFilters.new(f, graph)
        add_extensions @filters.extensions
      end

      # Return an array of filter options for the current route.
      def filters
        @filters ||= EdgeFilters.new(nil, graph)
      end

      def block=(block)
        if block
          filters.blocks = [block]
        else
          filters.blocks = []
        end
      end

      protected

      def build_pipeline
        filters.build_pipeline(self, *pipe_source)
      end

      def inspect_string
        if filters.any?
          "#{inspect_class_name}(#{filters})"
        else
          inspect_class_name
        end
      end
    end
  end
end
