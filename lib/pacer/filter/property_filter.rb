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
          VerticesIdentityRoute.new(base)
        elsif Pacer.edge? base
          EdgesIdentityRoute.new(base)
        else
          base
        end
      end
    end
  end

  module Filter
    module PropertyFilter
      module EdgeLabels
        # Specialize filter_pipe for edge labels.
        def filter_pipe(pipe, filters, block, expand_extensions)
          pipe, filters = expand_extension_conditions(pipe, filters) if expand_extensions
          labels = filters.select { |arg| arg.is_a? Symbol or arg.is_a? String }
          if labels.empty?
            super
          else
            label_pipe = Pacer::Pipes::LabelsFilterPipe.new
            label_pipe.set_labels labels
            label_pipe.set_starts pipe
            super(label_pipe, filters - labels, block, false)
          end
        end
      end

      def self.triggers
        [:filters, :block]
      end

      def filters=(filter_array)
        case filter_array
        when Array
          @filters = filter_array
        when nil
          @filters = []
        else
          @filters = [filter_array]
        end
        # Sometimes filters are modules. If they contain a Route submodule, extend this route with that module.
        add_extensions @filters
      end

      def block=(block)
        @block = block
      end

      # Return an array of filter options for the current route.
      def filters
        @filters ||= []
      end

      # Return the block filter for the current route.
      def block
        @block
      end

      protected

      def after_initialize
        if element_type == graph.element_type(:edge)
          extend EdgeLabels
        end
      end

      def attach_pipe(end_pipe)
        filter_pipe(end_pipe, @filters, @block, true)
      end

      # Appends the defined filter pipes to narrow the results passed through
      # the pipes for this route object.
      def filter_pipe(pipe, args_array, block, expand_extensions)
        if args_array and args_array.any?
          pipe, args_array = expand_extension_conditions(pipe, args_array) if expand_extensions
          pipe = args_array.select { |arg| arg.is_a? Hash }.inject(pipe) do |p, hash|
            hash.inject(p) do |p2, (key, value)|
              new_pipe = Pacer::Pipes::PropertyFilterPipe.new(key.to_s, value.to_java, Pacer::Pipes::ComparisonFilterPipe::Filter::NOT_EQUAL)
              new_pipe.set_starts p2 if p2
              new_pipe
            end
          end
        end
        if block
          pipe = Pacer::Pipes::BlockFilterPipe.new(pipe, self, block)
        end
        pipe
      end

      def expand_extension_conditions(pipe, args_array)
        modules = args_array.select { |obj| obj.is_a? Module or obj.is_a? Class }
        pipe = modules.inject(pipe) do |p, mod|
          if mod.respond_to? :route_conditions
            args_array = args_array + [*mod.route_conditions]
            p
          elsif mod.respond_to? :route
            route = mod.route(self)
            beginning_of_condition = route.send :route_after, self
            beginning_of_condition.send :source=, pipe if pipe
            route.send :iterator
          else
            pipe
          end
        end
        [pipe, args_array]
      end

      def inspect_string
        fs = "#{filters.inspect}" if filters.any?
        bs = '&block' if @block
        s = inspect_class_name
        if fs or bs
          s = "#{s}(#{ [fs, bs].compact.join(', ') })"
        end
        s
      end
    end
  end
end
