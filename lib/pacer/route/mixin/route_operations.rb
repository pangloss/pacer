module Pacer::Routes

  # Additional convenience and data analysis methods that can be mixed into
  # routes if they support the full route interface.
  module RouteOperations
    include BranchableRoute
    include BulkOperations

    def paths
      PathsRoute.new(self)
    end

    def context
      ContextRoute.new(self)
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
      route = route_class.pipe_filter(self, Pacer::Pipes::RandomFilterPipe, bias)
      route.add_extensions extensions
      route
    end

    # Do not return duplicate elements.
    def uniq(*filters, &block)
      if filters.any? or block
        filter(*filters, &block).uniq
      else
        route = route_class.pipe_filter(self, Pacer::Pipes::DuplicateFilterPipe)
        route.add_extensions extensions
        route
      end
    end

    def has?(element)
      any? { |e| e == element }
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
        route = route_class.pipe_filter(self, Pacer::Pipes::RangeFilterPipe, prop_or_subset, prop_or_subset + 1)
        route.add_extensions extensions
        route
      when Range
        end_index = prop_or_subset.end
        end_index += 1 unless prop_or_subset.exclude_end?
        route = route_class.pipe_filter(self, Pacer::Pipes::RangeFilterPipe, prop_or_subset.begin, end_index)
        route.add_extensions extensions
        route
      when Array
        if prop_or_subset.all? { |i| i.is_a? String or i.is_a? Symbol }
          map do |element|
            prop_or_subset.map { |i| element.get_property(i.to_s) }
          end
        end
      end
    end

    # Returns an array of element ids.
    def ids
      route = Pacer::Routes::ObjectRoute.new(self)
      route.pipe_class = Pacer::Pipes::IdPipe
      route
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
      else
        each do |e|
          result[e] += 1
        end
      end
      result
    end

    def most_frequent(range = 0)
      group_count.sort_by { |k, v| -v }.map { |k, v| k }[range]
    end

    def all_but_most_frequent(start_at = 1)
      elements = group_count.sort_by { |k, v| -v }.map { |k, v| k }[start_at..-1]
      elements ||= []
      elements.to_route(:based_on => self)
    end

    # Delete all matching elements.
    def delete!
      uniq.bulk_job { |e| e.delete! }
    end

    # Store the current intermediate element in the route's vars hash by the
    # given name so that it is accessible subsequently in the processing of the
    # route.
    def as(name)
      route = if vertices_route?
          VertexVariableRoute.new(self, name)
        elsif edges_route?
          EdgeVariableRoute.new(self, name)
        elsif mixed_route?
          MixedVariableRoute.new(self, name)
        end
      route.add_extensions extensions
      route
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
      route = if range.is_a? Fixnum
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
      route.add_extensions extensions
      route
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

    def clone_into(target_graph, opts = {})
      bulk_job(nil, target_graph) do |element|
        element.clone_into(target_graph, opts)
      end
    end

    def copy_into(target_graph, opts = {})
      bulk_job(nil, target_graph) { |element| element.copy_into(target_graph, opts) }
    end

    def build_index(index, index_key = nil, property = nil, create = true)
      index_name = index
      unless index.is_a? com.tinkerpop.blueprints.pgm.Index
        index = graph.indices.find { |i| i.index_name == index.to_s }
      end
      unless index
        if create
          index = graph.create_index index_name, graph.element_type(first), Pacer.manual_index
        else
          raise "No index found for #{ index } on #{ graph }" unless index
        end
      end
      index_key ||= index.index_name
      property ||= index_key
      if block_given?
        bulk_job do |element|
          value = yield(element)
          index.put(index_key, value, element) if value
        end
      else
        bulk_job do |element|
          value = element[property]
          index.put(index_key, value, element) if value
        end
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
