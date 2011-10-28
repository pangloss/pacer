module Pacer
  module Filter
    module PropertyFilter
      class Filters
        attr_reader :properties, :extensions, :route_modules
        attr_accessor :wrapper, :blocks

        # Allow Pacer to use index counts to determine which index has
        # the least number elements for the available keys in the query.
        #
        # @attr [Boolean] choose_best_index
        attr_accessor :choose_best_index

        # Allow Pacer to use manual indices without explicitly
        # referencing them by name.
        #
        # @example Explicit manual index:
        #
        #   graph.v(:index_name => { :index_key => value })
        #
        # @example Non-explicit index lookup:
        #
        #   graph.v(:index_key => value)
        #
        # @attr [Boolean] search_manual_indices
        attr_accessor :search_manual_indices

        protected

        attr_accessor :non_ext_props

        public

        def initialize(filters)
          @properties = []
          @blocks = []
          @extensions = []
          @wrapper = nil
          @route_modules = []
          @non_ext_props = []
          @best_index_value = nil
          add_filters filters, nil
        end

        # Set which graph this filter is currently operating on
        #
        # @note this is not threadsafe if you are reusing predefined
        #   routes on multiple graphs.
        #
        # @attr [GraphMixin] g a graph
        attr_reader :graph

        def graph=(g)
          if graph != g
            reset_properties
            @graph = g
          end
        end

        # Set which indices are available to be used to determine the
        # best_index.
        #
        # @attr [Array<Pacer::IndexMixin>] i an array of indices
        attr_reader :indices

        def indices=(i)
          if indices != i
            reset_properties
            @indices = i
          end
        end

        def add_filter(filter, extension)
          case filter
          when Hash
            reset_properties
            filter.each do |k, v|
              self.non_ext_props << [k.to_s, v] unless extension
              self.properties << [k.to_s, v]
            end
          when Module, Class
            if filter.is_a? Class and filter.ancestors.include? Pacer::Wrappers::ElementWrapper
              self.wrapper = filter
            else
              self.extensions << filter
            end
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
          route_modules.each do |mod|
            extension_route = mod.route(Pacer::Route.empty(route))
            s, e = extension_route.send :build_pipeline
            s.setStarts(pipe) if pipe
            start_pipe ||= s
            pipe = e
          end
          encoded_properties.each do |key, value|
            new_pipe = PropertyFilterPipe.new(key, value, Pacer::Pipes::EQUAL)
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
          [start_pipe, pipe]
        end

        def any?
          properties.any? or blocks.any? or route_modules.any? or extensions.any?
        end

        def extensions_only?
          properties.none? and blocks.none? and route_modules.none? and (extensions.any? or wrapper)
        end

        def to_s
          strings = []
          strings << [wrapper.name] if wrapper
          strings.concat extensions.map { |e| e.name }
          strings.concat((non_ext_props - [@best_index_value]).map { |k, v| "#{ k }==#{ v.inspect }" })
          strings.concat blocks.map { '&block' }
          strings.concat route_modules.map { |mod| mod.name }
          strings.join ', '
        end

        def best_index(element_type)
          result = find_best_index(element_type)
          # the call to find_best_index produces @best_index_value:
          if properties.delete @best_index_value
            @encoded_properties = nil
          end
          result
        end

        protected

        def find_best_index(element_type)
          return @best_index if @best_index
          avail = available_indices(element_type)
          return nil if avail.empty?
          index_options = []
          yield avail, index_options if block_given?
          properties.each do |k, v|
            if v.is_a? Hash
              v.each do |k2, v2|
                if (idxs = avail["name:#{k}"]).any?
                  if choose_best_index
                    idxs.each do |idx|
                      index_options << [idx.count(k2, encode_value(v2)), [idx, k2, v2], [k, v]]
                    end
                  else
                    @best_index_value = [k, v]
                    return @best_index = [idxs.first, k2, v2]
                  end
                end
              end
            elsif (idxs = (avail["key:#{k}"] + avail[:all])).any?
              if choose_best_index
                idxs.each do |idx|
                  index_options << [idx.count(k, encode_value(v)), [idx, k, v], [k, v]]
                end
              else
                @best_index_value = [k, v]
                return @best_index = [idxs.first, k, v]
              end
            else
              nil
            end
          end
          index_options = index_options.sort_by do |a|
            count = a.first
            if count == 0 and search_manual_indices
              # Only use 0 result indices if there is no alternative
              # because most manual indices won't be populating the
              # data in question.
              java.lang.Integer::MAX_VALUE
            else
              count
            end
          end
          _, @best_index, @best_index_value = index_options.first || [nil, [], []]
          @best_index
        end

        def reset_properties
          @encoded_properties = nil
          if @best_index_value
            # put removed index property back...
            properties << @best_index_value
          end
          @best_index = nil
          @best_index_value = nil
          @available_indices = nil
        end

        def encoded_properties
          @encoded_properties ||= properties.map do |k, v|
            [k, encode_value(v)]
          end
        end

        def available_indices(element_type)
          return @available_indices if @available_indices
          @available_indices = Hash.new { |h, k| h[k] = [] }
          return @available_indices unless indices
          index_class = graph.index_class(element_type)
          indices.each do |index|
            next unless index.index_class == index_class
            if index.index_type == Pacer.automatic_index
              if keys = index.getAutoIndexKeys
                keys.each do |key|
                  @available_indices["key:#{key}"] << index
                end
              else
                @available_indices[:all] << index
              end
            else
              @available_indices["name:#{index.index_name}"] = [index]
              @available_indices[:all] << index if search_manual_indices
            end
          end
          @available_indices
        end

      end
    end
  end
end
