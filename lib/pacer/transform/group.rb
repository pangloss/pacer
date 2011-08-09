module Pacer
  module Routes
    module RouteOperations
      def group
        chain_route :transform => :group
      end
    end
  end

  # Here's an example of the syntax I want:
  # trims.limit(10).
  #   group.key { |t| t[:id] }.values { |t| t.out_e.counted.cap }.
  #   reduce.key_start { |k| 0 }.value { |start, k, v| start + v  }.
  #   reduce(0).value { |start, k, v| start + v }.buffer(100).
  #   group.key { |k, v| v % 100 }.values { |k, v| k }.
  #
  # trims.limit(10).
  #   map.key { |t| t[:id] }.values { |t| t.out_e.counted.cap }.to_redis
  #
  # Pacer.source { |callback| callback.yield 1 }
  #
  #
  class Group
    attr_reader :key
    attr_reader :all_values

    def initialize(key, values)
      @key = key
      @all_values = Hash[values]
    end

    def values(name = :default)
      @all_values[name]
    end

    def set_values(name, values)
      @all_values[name] = values
    end

    def combine!(group)
      group.all_values.each do |name, vals|
        set = values(name)
        vals.each do |value|
          set << value
        end
      end
    end

    def clone_values
      Hash[@all_values.map { |key, val|
        [key, val.map { |v| v }]
      }]
    end

    def clone
      Pacer::Group.new(key, clone_values)
    end

    def reducer(start)
      group = Pacer::Group.new(key, [])
      if start.is_a? Proc
        group.all_values.default_proc = start
      else
        group.all_values.default = start
      end
      group
    end

    def inspect
      prefix = "#<Group #{ key.inspect } "
      "#{prefix}#{ all_values.map { |k,v| [k, ': ', v.inspect].join }.join("  ") } >"
    end
  end

  module Transform
    module Group
      attr_accessor :key_route, :values_routes

      def key_map(&block)
        @key_route = map_route block
        self
      end

      def values_map(name = :values, &block)
        @values_routes << [name, map_route(block)]
        self
      end

      def key_route(&block)
        @key_route = block_route(block)
        self
      end

      def values_route(name = :values, &block)
        @values_routes << [name, block_route(block)]
        self
      end

      def combine_all
        hash = {}
        each do |group|
          a = hash[group.key]
          if a
            a.combine! group
          else
            hash[group.key] = group.clone
          end
        end
        hash
      end

      def combine(name = :default)
        hash = Hash.new { |h, k| h[k] = [] }
        each do |group|
          group.values(name).each do |value|
            hash[group.key] << value
          end
        end
        hash
      end

      def reduce_all(start)
        hash = {}
        each do |group|
          reducer = hash[group.key] ||= group.reducer(start)
          group.all_values.each do |name, values|
            result = reducer.values(name)
            values.each do |value|
              result = yield result, name, value
            end
            reducer.set_values(name, result)
          end
        end
        hash
      end

      def reduce(start, name = :default)
        if start.is_a? Proc
          hash = Hash.new(&start)
        else
          hash = Hash.new(start)
        end
        each do |group|
          result = hash[group.key]
          group.values(name).each do |value|
            result = yield result, value
          end
          hash[group.key] = result
        end
        hash
      end

      protected

      def after_initialize
        @values_routes = []
      end

      def map_route(block)
        Pacer::Route.empty(self).
          chain_route({:transform => :map, :block => block, :element_type => :object}).
          route
      end

      def block_route(block)
        block.call(Pacer::Route.empty(self)).route
      end

      def identity_route
        Pacer::Route.empty(self).chain_route(:pipe_class => Pacer::Pipes::IdentityPipe,
                                             :route_name => '@').route
      end

      def ensure_routes
        key_route = @key_route
        values_routes = @values_routes
        key_route ||= identity_route
        values_routes = [[:default, identity_route]] if values_routes.empty?
        key_route.route
        values_routes.each { |name, r| r.route }
        [key_route, values_routes]
      end

      def attach_pipe(end_pipe)
        key_route, values_routes = ensure_routes
        pipe = Pacer::Pipes::GroupPipe.new
        pipe.addKeyPipe *key_route.send(:build_pipeline)
        values_routes.each do |name, route|
          pipe.addValuesPipe name, *route.send(:build_pipeline)
        end
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        key_route, values_routes = ensure_routes
        "#{ inspect_class_name }(#{ key_route.inspect }: #{ Hash[values_routes].inspect })"
      end
    end
  end
end
