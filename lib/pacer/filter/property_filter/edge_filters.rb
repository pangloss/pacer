module Pacer
  module Filter
    module PropertyFilter
      class EdgeFilters < Filters
        attr_accessor :labels

        protected

        attr_accessor :non_ext_labels

        public

        def initialize(filters)
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

        def to_s
          if labels.any?
            [non_ext_labels.map { |l| l.to_sym.inspect }.join(', '), super].reject { |s| s == '' }.join ', '
          else
            super
          end
        end
      end
    end
  end
end
