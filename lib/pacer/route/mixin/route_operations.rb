module Pacer::Routes
  module RouteOperations
    def paths
      PathsRoute.new(self)
    end

    # Create a new TinkerGraph based on the paths of all matching elements.
    def subgraph
      paths.subgraph
    end

    # Return elements based on a bias:1 chance.
    #
    # If given an integer (n) > 0, bias is calcualated at 1 / n.
    def random(bias = 0.5)
      bias = 1 / bias.to_f if bias.is_a? Fixnum and bias > 0
      route_class.pipe_filter(self, Pacer::Pipes::RandomFilterPipe, bias)
    end

    # Do not return duplicate elements.
    def uniq
      route_class.pipe_filter(self, Pacer::Pipes::DuplicateFilterPipe)
    end

    # Accepts a string or symbol to return an array of matching properties, or
    # an integer to return the element at the given offset, or a range to
    # return all elements between the offsets within the range.
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

    # Returns an array of element ids.
    def ids
      map { |e| e.id }
    end

    # Creates a hash where the key is the properties and return value of the
    # given block, and the value is the number of times each key was found in
    # the results set.
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

    # Delete all matching elements.
    def delete!
      map { |e| e.delete! }
    end

    # Store the current intermediate element in the route's vars hash by the
    # given name so that it is accessible subsequently in the processing of the
    # route.
    def as(name)
      if vertices_route?
        VertexVariableRoute.new(self, name)
      elsif edges_route?
        EdgeVariableRoute.new(self, name)
      elsif mixed_route?
        MixedVariableRoute.new(self, name)
      end
    end

    # Branch the route on a path defined within the given block. Call this
    # method multiple times in a row to branch the route over different paths
    # before merging back.
    def branch(&block)
      br = BranchedRoute.new(self, block)
      if br.branch_count == 0
        self
      else
        br
      end
    end

    # Returns true if this route could contain both vertices and edges.
    def mixed_route?
      self.is_a? MixedRouteModule
    end

    # Returns true if this route countains only vertices.
    def vertices_route?
      self.is_a? VerticesRouteModule
    end

    # Returns true if this route countains only edges.
    def edges_route?
      self.is_a? EdgesRouteModule
    end

    # Apply the given path fragment multiple times in succession. If a range is given, the route
    # is branched and each number of repeats is processed in a seperate branch before being
    # merged back. That is useful if a pattern may be nested to varying depths.
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
