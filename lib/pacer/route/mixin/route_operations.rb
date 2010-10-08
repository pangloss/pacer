module Pacer::Routes
  module RouteOperations
    def paths
      PathsRoute.new(self)
    end

    def subgraph
      paths.subgraph
    end

    # bias is the chance the element will be returned from 0 to 1 (0% to 100%)
    def random(bias = 0.5)
      route_class.pipe_filter(self, Pacer::Pipes::RandomFilterPipe, bias)
    end

    def uniq
      route_class.pipe_filter(self, Pacer::Pipes::DuplicateFilterPipe)
    end

    def [](prop_or_subset)
      case prop_or_subset
      when String, Symbol
        # could use PropertyPipe but that would mean supporting objects that I don't think
        # would have much purpose.
        map do |element|
          element.get_property(prop_or_subset.to_s)
        end
      when Fixnum
        route_class.pipe_filter(self, Pacer::Pipes::RangeFilterPipe, prop_or_subset, prop_or_subset + 1)
      when Range
        end_index = prop_or_subset.end
        end_index += 1 unless prop_or_subset.exclude_end?
        route_class.pipe_filter(self, Pacer::Pipes::RangeFilterPipe, prop_or_subset.begin, end_index)
      when Array
      end
    end

    def ids
      map { |e| e.id }
    end

    def group_count(*props)
      result = Hash.new(0)
      props = props.map { |p| p.to_s }
      if props.empty? and block_given?
        each { |e| result[yield(e)] += 1 }
      elsif block_given?
        each do |e|
          key = props.map { |p| e.get_property(p) }
          key << yield(e)
          result[key] += 1
        end
      elsif props.count == 1
        prop = props.first
        each do |e|
          result[e.get_property(prop)] += 1
        end
      elsif props.any?
        each do |e|
          result[props.map { |p| e.get_property(p) }] += 1
        end
      end
      result
    end

    def group_map(into = [], operation = :<<)
      result = Hash.new { |h,k| h[k] = into.clone }
      each do |e|
        k, v = yield e
        result[k] = result[k].send(operation, v)
      end
      result
    end

    def delete!
      map { |e| e.delete! }
    end

    def as(name)
      if vertices_route?
        VertexVariableRoute.new(self, name)
      elsif edges_route?
        EdgeVariableRoute.new(self, name)
      elsif mixed_route?
        MixedVariableRoute.new(self, name)
      end
    end

    def branch(&block)
      br = BranchedRoute.new(self, block)
      if br.branch_count == 0
        self
      else
        br
      end
    end

    def mixed_route?
      self.is_a? MixedRouteModule
    end

    def vertices_route?
      self.is_a? VerticesRouteModule
    end

    def edges_route?
      self.is_a? EdgesRouteModule
    end

    def repeat(range)
      if range.is_a? Fixnum
        range.to_enum(:times).inject(self) do |route_end, count|
          yield route_end
        end
      else
        br = BranchedRoute.new(self)
        range.each do |count|
          br.branch do |branch_root|
            count.to_enum(:times).inject(branch_root) do |route_end, count|
              yield route_end
            end
          end
        end
        br
      end
    end

    protected

    def has_routable_class?
      true
    end

    def route_class
      route = self
      route = route.back until route.has_routable_class?
      route.class
    end
  end
end
