require 'pacer/filter/property_filter/filters'
require 'pacer/filter/property_filter/edge_filters'

module Pacer
  class Route
    class << self
      def filters(graph, filters)
        if filters? filters
          filters
        elsif filters? filters.first
          filters.first
        else
          Pacer::Filter::PropertyFilter::Filters.new(graph, filters)
        end
      end

      def edge_filters(graph, filters)
        if filters? filters
          filters
        elsif filters? filters.first
          filters.first
        else
          Pacer::Filter::PropertyFilter::EdgeFilters.new(graph, filters)
        end
      end

      def filters?(filters)
        filters.is_a? Pacer::Filter::PropertyFilter::Filters
      end

      def property_filter_before(base, args, block)
        filters = Pacer::Route.edge_filters(base.graph, args)
        filters.blocks = [block] if block
        args = chain_args(filters)
        if filters.extensions_only? and base.is_a? Route
          yield base.chain_route(args)
        elsif filters and filters.any?
          yield base.chain_route(args.merge!(filter: :property, filters: filters))
        else
          yield base
        end
      end

      def property_filter(base, args, block)
        filters = Pacer::Route.edge_filters(base.graph, args)
        filters.blocks = [block] if block
        args = chain_args(filters)
        if filters.extensions_only? and base.is_a? Route
          base.chain_route(args)
        elsif filters.any?
          base.chain_route(args.merge!(filter: :property, filters: filters))
        elsif base.is_a? Pacer::Wrappers::ElementWrapper
          base.chain_route({})
        else
          base
        end
      end

      def chain_args(filters)
        if filters.wrapper or (filters.extensions and not filters.extensions.empty?)
          { extensions: filters.extensions, wrapper: filters.wrapper }
        else
          {}
        end
      end
    end
  end

  module Filter
    module PropertyFilter
      #import com.tinkerpop.pipes.filter.LabelCollectionFilterPipe
      import com.tinkerpop.pipes.filter.PropertyFilterPipe

      def filters=(f)
        if f.is_a? Filters
          @filters = f
        else
          @filters = EdgeFilters.new(graph, f)
        end
      end

      # Return an array of filter options for the current route.
      def filters
        @filters ||= EdgeFilters.new(graph, nil)
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
