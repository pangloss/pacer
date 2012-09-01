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
          yield base.chain_route(extensions: filters.extensions, wrapper: filters.wrapper)
        elsif filters and filters.any?
          yield base.chain_route(filter: :property, filters: filters,
                                 extensions: filters.extensions, wrapper: filters.wrapper)
        else
          yield base
        end
      end

      def property_filter(base, filters, block)
        filters = Pacer::Route.edge_filters(filters)
        filters.blocks = [block] if block
        if filters.extensions_only? and base.is_a? Route
          base.chain_route(extensions: filters.extensions, wrapper: filters.wrapper)
        elsif filters and filters.any?
          base.chain_route(filter: :property, filters: filters,
                           extensions: filters.extensions, wrapper: filters.wrapper)
        elsif base.is_a? Pacer::Wrappers::ElementWrapper
          base.chain_route({})
        else
          base
        end
      end
    end
  end

  module Filter
    module PropertyFilter
      #import com.tinkerpop.pipes.filter.LabelCollectionFilterPipe
      import com.tinkerpop.gremlin.pipes.filter.PropertyFilterPipe

      def filters=(f)
        if f.is_a? Filters
          @filters = f
        else
          @filters = EdgeFilters.new(f)
        end
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
