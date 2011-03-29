module Pacer::Routes

  # Additional convenience and data analysis methods that can be mixed into
  # routes if they support the full route interface.
  module RouteOperations
    include BulkOperations

    def paths
      PathsRoute.new(self)
    end

    def context
      ContextRoute.new(self)
    end

    # Return elements based on a bias:1 chance.
    #
    # If given an integer (n) > 0, bias is calcualated at 1 / n.
    def random(bias = 0.5)
      bias = 1 / bias.to_f if bias.is_a? Fixnum and bias > 0
      chain_route :pipe_class => Pacer::Pipes::RandomFilterPipe, :pipe_args => bias
    end

    def has?(element)
      any? { |e| e == element }
    end

    # Creates a hash where the key is the properties and return value of the
    # given block, and the value is the number of times each key was found in
    # the results set.
    def group_count(*props)
      result = Hash.new(0)
      props = props.collect { |p| p.to_s }
      if props.empty? and block_given?
        each { |e| result[yield(e)] += 1 }
      elsif block_given?
        each do |e|
          key = props.collect { |p| e.get_property(p) }
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
          result[props.collect { |p| e.get_property(p) }] += 1
        end
      else
        each do |e|
          result[e] += 1
        end
      end
      result
    end

    def most_frequent(range = 0, include_counts = false)
      if include_counts
        result = group_count.sort_by { |k, v| -v }[range]
        if not result and range.is_a? Fixnum
          []
        else
          result
        end
      else
        result = group_count.sort_by { |k, v| -v }[range]
        if range.is_a? Fixnum
          result.first if result
        elsif result
          result.collect { |k, v| k }.to_route(:based_on => self)
        else
          [].to_route(:based_on => self)
        end
      end
    end

    # Store the current intermediate element in the route's vars hash by the
    # given name so that it is accessible subsequently in the processing of the
    # route.
    def as(name)
      chain_route :modules => VariableRouteModule, :variable_name => name
    end

    # Returns true if this route could contain both vertices and edges.
    def mixed_route?
      self.is_a? Pacer::Core::Graph::MixedRoute
    end

    # Returns true if this route countains only vertices.
    def vertices_route?
      self.is_a? Pacer::Core::Graph::VerticesRoute
    end

    # Returns true if this route countains only edges.
    def edges_route?
      self.is_a? Pacer::Core::Graph::EdgesRoute
    end

    # Apply the given path fragment multiple times in succession. If a range is given, the route
    # is branched and each number of repeats is processed in a seperate branch before being
    # merged back. That is useful if a pattern may be nested to varying depths.
    def repeat(range)
      # TODO: switch to using loop
     #route = if range.is_a? Fixnum
     #    range.to_enum(:times).inject(self) do |route_end, count|
     #      yield route_end
     #    end
     #  else
     #    br = BranchedRoute.new(self)
     #    range.each do |count|
     #      br.branch do |branch_root|
     #        count.to_enum(:times).inject(branch_root) do |route_end, count|
     #          yield route_end
     #        end
     #      end
     #    end
     #    br
     #  end
     #route.add_extensions extensions
     #route
    end

    def pages(elements_per_page = 1000)
      page = []
      results = []
      idx = 0
      each do |e|
        page << e
        idx += 1
        if idx % elements_per_page == 0
          results << yield(page)
          page = []
        end
      end
      yield page unless page.empty?
      results
    end

    protected

    def has_routable_class?
      true
    end
  end
end
