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

      class ElementFilters
        attr_accessor :properties, :blocks, :extensions, :route_modules

        attr_reader :graph

        protected

        attr_accessor :non_ext_props

        public

        def initialize(filters, graph)
          self.properties = []
          self.blocks = []
          self.extensions = []
          self.route_modules = []
          self.non_ext_props = []
          self.graph = graph
          add_filters filters, nil
        end

        def graph=(g)
          if @graph != g
            @encoded_properties = nil
            @graph = g
          end
        end

        def encoded_properties
          @encoded_properties ||= properties.map do |k, v|
            [k, encode_value(v)]
          end
        end

        def add_filter(filter, extension)
          case filter
          when Hash
            filter.each do |k, v|
              self.non_ext_props << [k, v] unless extension
              self.properties << [k.to_s, v]
            end
          when Module, Class
            self.extensions << filter
            if filter.respond_to? :route_conditions
              add_filters filter.route_conditions, filter
            end
            if filter.respond_to? :route
              self.route_modules << filter
            end
          when Array
            add_filters(filter, extension)
          when nil
          else
            raise "Unknown filter: #{ filter.class }: #{ filter.inspect }"
          end
        end

        def add_filters(filters, extension)
          if filters.is_a? Array
            filters.each do |filter|
              add_filter filter, extension
            end
          else
            add_filter filters, extension
          end
        end

        def encode_value(value)
          value = graph.encode_property(value)
          if value.respond_to? :to_java
            jvalue = value.to_java
          elsif value.respond_to? :to_java_string
            jvalue = value.to_java_string
          else
            jvalue = value
          end
        end

        def build_pipeline(route, start_pipe, pipe = nil)
          self.graph = route.graph
          pipe ||= start_pipe
          encoded_properties.each do |key, value|
            new_pipe = PropertyFilterPipe.new(key, value, Pacer::Pipes::ComparisonFilterPipe::Filter::NOT_EQUAL)
            new_pipe.set_starts pipe if pipe
            Pacer.debug_pipes << { :name => key, :start => pipe, :end => new_pipe } if Pacer.debug_pipes
            pipe = new_pipe
            start_pipe ||= pipe
          end
          blocks.each do |block|
            block_pipe = Pacer::Pipes::BlockFilterPipe.new(route, block)
            block_pipe.set_starts pipe if pipe
            Pacer.debug_pipes << { :name => 'block', :start => pipe, :end => block_pipe } if Pacer.debug_pipes
            pipe = block_pipe
            start_pipe ||= pipe
          end
          route_modules.each do |mod|
            extension_route = mod.route(Pacer::Route.empty(route))
            s, e = extension_route.send :build_pipeline
            s.setStarts(pipe) if pipe
            start_pipe ||= s
            pipe = e
          end
          [start_pipe, pipe]
        end

        def any?
          properties.any? or blocks.any? or route_modules.any?
        end

        def inspect
          strings = extensions.map { |e| e.name }
          strings.concat non_ext_props.map { |k, v| "#{ k }==#{ v.inspect }" }
          strings.concat blocks.map { '&block' }
          strings.concat route_modules.map { |mod| mod.name }
          strings.join ', '
        end
      end

      class EdgeFilters < ElementFilters
        attr_accessor :labels

        protected

        attr_accessor :non_ext_labels

        public

        def initialize(filters, graph)
          self.labels = []
          self.non_ext_labels = []
          super
        end

        def add_filter(filter, extension)
          case filter
          when String, Symbol
            self.non_ext_labels << filter
            self.labels << filter.to_s
          else
            super
          end
        end

        def build_pipeline(route, start_pipe, pipe = nil)
          pipe ||= start_pipe
          if labels.any?
            label_pipe = LabelCollectionFilterPipe.new labels, Pacer::Pipes::NOT_EQUAL
            label_pipe.set_starts pipe if pipe
            Pacer.debug_pipes << { :name => labels.inspect, :start => pipe, :end => block_pipe } if Pacer.debug_pipes
            pipe = label_pipe
            start_pipe ||= pipe
          end
          super(route, start_pipe, pipe)
        end

        def any?
          labels.any? or super
        end

        def inspect
          if labels.any?
            [non_ext_labels.map { |l| l.to_sym.inspect }.join(', '), super].reject { |s| s == '' }.join ', '
          else
            super
          end
        end
      end

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
          "#{inspect_class_name}(#{filters.inspect})"
        else
          inspect_class_name
        end
      end
    end
  end
end
