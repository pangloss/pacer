module Pacer::Routes

  # Additional convenience and data analysis methods that can be mixed into
  # routes if they support the full route interface.
  module RouteOperations
    include BulkOperations

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
          key = props.collect { |p| e.getProperty(p) }
          key << yield(e)
          result[key] += 1
        end
      elsif props.count == 1
        prop = props.first
        each do |e|
          result[e.getProperty(prop)] += 1
        end
      elsif props.any?
        each do |e|
          result[props.collect { |p| e.getProperty(p) }] += 1
        end
      else
        each do |e|
          result[e] += 1
        end
      end
      result
    end
    alias frequencies group_count

    def frequency_groups(*props)
      result = Hash.new { |h, k| h[k] = [] }
      group_count(*props).each { |k, v| result[v] << k }
      result
    end

    def frequency_counts(*props)
      result = Hash.new 0
      group_count(*props).each { |k, v| result[v] += 1 }
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

    # Creates a terse, human-friendly name for the class based on its
    # element type, function and info.
    # @return [String]
    def inspect_class_name
      s = case element_type
          when :vertex
            'V'
          when :edge
            'E'
          when :object
            'Obj'
          when :mixed
            'Elem'
          else
            element_type.to_s.capitalize
          end
      s = "#{s}-#{function.name.split('::').last.sub(/Filter|Route$/, '')}" if function
      s = "#{s} #{ @info }" if @info
      s
    end
  end
end
