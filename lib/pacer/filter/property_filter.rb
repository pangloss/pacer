require 'pacer/filter/property_filter/filters'
require 'pacer/filter/property_filter/edge_filters'

module Pacer
  class Route
    class << self
      def filters(filters)
        if filters? filters
          filters
        elsif filters? filters.first
          filters.first
        else
          Pacer::Filter::PropertyFilter::Filters.new(filters)
        end
      end

      def edge_filters(filters)
        if filters? filters
          filters
        elsif filters? filters.first
          filters.first
        else
          Pacer::Filter::PropertyFilter::EdgeFilters.new(filters)
        end
      end

      def filters?(filters)
        filters.is_a? Pacer::Filter::PropertyFilter::Filters
      end

      def property_filter_before(base, filters, block)
        filters = Pacer::Route.edge_filters(filters)
        filters.blocks = [block] if block
        if filters.extensions_only? and base.is_a? Route
          base.add_extensions(filters.extensions)
          yield base
        elsif filters and filters.any?
          yield new(:back => base, :filter => :property, :filters => filters)
        else
          yield base
        end
      end

      def property_filter(base, filters, block)
        $f = filters = Pacer::Route.edge_filters(filters)
        filters.blocks = [block] if block
        if filters.extensions_only? and base.is_a? Route
          base.wrapper ||= filters.wrapper if filters.wrapper
          base.add_extensions(filters.extensions)
        elsif filters and filters.any?
          new(:back => base, :filter => :property, :filters => filters)
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
      #import com.tinkerpop.pipes.filter.LabelCollectionFilterPipe
      import com.tinkerpop.pipes.filter.PropertyFilterPipe

      def self.triggers
        [:filters]
      end

      def filters=(f)
        if f.is_a? Filters
          @filters = f
        else
          @filters = EdgeFilters.new(f)
        end
        self.wrapper ||= @filters.wrapper if @filters.wrapper
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
