module Pacer
  module Filter
    module PropertyFilter
      class EdgeFilters < Filters
        attr_accessor :labels

        protected

        attr_accessor :non_ext_labels

        public

        def initialize(filters)
          @best_index = nil
          self.labels = []
          self.non_ext_labels = []
          super
        end

        def add_filter(filter, extension)
          case filter
          when String, Symbol
            reset_properties
            self.non_ext_labels << filter
            self.labels << filter.to_s
          else
            super
          end
        end

        def build_pipeline(route, start_pipe = nil, pipe = nil)
          pipe ||= start_pipe
          if labels.any?
            label_pipe = Pacer::Pipes::LabelCollectionFilterPipe.new labels
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
            [labels.map { |l| l.to_sym.inspect }.join(', '), super].reject { |s| s == '' }.join ', '
          else
            super
          end
        end

        def best_index(route)
          index, key, value = find_best_index(route)
          if key == 'label'
            labels.delete value
          end
          super
        end

        protected

        def reset_properties
          @encoded_properties = nil
          if @best_index
            # put removed index label back...
            i, k, v = @best_index
            labels << v if k == 'label'
          end
          super
        end

        def find_best_index(route)
          super do |avail, index_options|
            labels.each do |label|
              if idxs = avail["key:label"]
                if choose_best_index
                  idxs.each do |idx|
                    index_options << [idx.count('label', label), idx, k, v]
                  end
                else
                  return @best_index = [idxs.first, 'label', label]
                end
              end
            end
          end
        end
      end
    end
  end
end
