require 'pacer/filter/property_filter/filters'
require 'pacer/filter/property_filter/edge_filters'

module Pacer
  class Route
    class << self
      def filters(filters)
        Pacer::Filter::PropertyFilter::Filters.new(filters)
      end

      def edge_filters(filters)
        Pacer::Filter::PropertyFilter::EdgeFilters.new(filters)
      end

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

      def filters=(f)
        if f.is_a? Filters
          @filters = f
        else
          @filters = EdgeFilters.new(f)
        end
        add_extensions @filters.extensions
      end

      # Return an array of filter options for the current route.
      def filters
        @filters ||= EdgeFilters.new(nil)
      end

      def block=(block)
        if block
          filters.blocks = [block]
        else
          filters.blocks = []
        end
      end

      def block
        filters.blocks.first
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
