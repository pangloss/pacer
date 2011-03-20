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
      module EdgeLabels
        # Specialize filter_pipe for edge labels.
        def filter_pipe(pipe, filters, block, expand_extensions)
          pipe, filters = expand_extension_conditions(pipe, filters) if expand_extensions
          labels = filters.select { |arg| arg.is_a? Symbol or arg.is_a? String }
          if labels.empty?
            super
          else
            label_pipe = Pacer::Pipes::LabelCollectionFilterPipe.new labels.collect { |l| l.to_s }, Pacer::Pipes::NOT_EQUAL
            label_pipe.set_starts pipe if pipe
            super(label_pipe, filters - labels, block, false)
          end
        end
      end

      def self.triggers
        [:filters]
      end

      attr_accessor :block

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

      # Return an array of filter options for the current route.
      def filters
        @filters ||= []
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
              if value.respond_to? :to_java
                jvalue = value.to_java
              elsif value.respond_to? :to_java_string
                jvalue = value.to_java_string
              else
                jvalue = value
              end
              new_pipe = Pacer::Pipes::PropertyFilterPipe.new(key.to_s, jvalue, Pacer::Pipes::ComparisonFilterPipe::Filter::NOT_EQUAL)
              new_pipe.set_starts p2 if p2
              new_pipe
            end
          end
        end
        if block
          block_pipe = Pacer::Pipes::BlockFilterPipe.new(self, block)
          block_pipe.set_starts pipe if pipe
          pipe = block_pipe
        end
        pipe
      end

      def expand_extension_conditions(pipe, args_array)
        modules = args_array.select { |obj| obj.is_a? Module or obj.is_a? Class }
        pipe = modules.inject(pipe) do |p, mod|
          if mod.respond_to? :route_conditions
            if mod.route_conditions.is_a? Array
              args_array = args_array + mod.route_conditions
            else
              args_array = args_array + [mod.route_conditions]
            end
            p
          elsif mod.respond_to? :route
            route = mod.route(Pacer::Route.empty(self))
            s, e = route.send :build_pipeline
            s.setStarts(p) if p
            e
          else
            p
          end
        end
        [pipe, args_array]
      end

      def inspect_string
        fs = filters.map do |f|
          if f.is_a? Hash
            f.map { |k, v| "#{ k }==#{ v.inspect }" }
          else
            f.inspect
          end
        end
        fs << '&block' if @block
        s = inspect_class_name
        if fs or bs
          s = "#{s}(#{ fs.join(', ') })"
        end
        s
      end
    end
  end
end
