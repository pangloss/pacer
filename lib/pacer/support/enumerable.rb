# Extend the built-in Enumerable module:
module Enumerable

  def one?
    counter = 0
    each do
      return false if counter == 1
      counter += 1
    end
    counter == 1
  end

  def many?
    counter = 0
    any? { if counter == 1; true; else; counter += 1; false; end }
  end

  # Transform the enumerable into a java HashSet.
  def to_hashset(method = nil, *args)
    return self if self.is_a? java.util.HashSet and not method
    hs = java.util.HashSet.new
    iter = self.each rescue nil
    if not iter and respond_to? :iterator
      iter = self.iterator
    end
    e = iter.next
    if method
      while true
        hs.add e.send(method, *args)
        e = iter.next
      end
    else
      while true
        hs.add e
        e = iter.next
      end
    end
  rescue StopIteration
    hs
  rescue NativeException => e
    if (e.cause.kind_of?(java.util.NoSuchElementException))
      hs
    else
      raise
    end
  end

  # NOTE: if this is a collection of wrapped vertices or edges, Java pipes
  # may crash with something like:
  #
  #   NativeException: java.lang.ClassCastException: org.jruby.RubyObject cannot be cast to com.tinkerpop.blueprints.Element
  #
  # You can work around that by passing the option :unwrap => true or
  # setting the :based_on parameter to a route that has extensions.
  def to_route(opts = {})
    if self.is_a? Pacer::Core::Route
      self
    else
      based_on = opts[:based_on]
      if opts[:unwrap] or based_on and (based_on.wrapper or based_on.extensions.any?) and based_on.is_a? Pacer::Core::Graph::ElementRoute
        source = Pacer::Route.new(:source => self, :element_type => :object).map { |e| e.element }
      else
        source = self
      end
      if based_on
        Pacer::Route.new(:source => source, :element_type => opts.fetch(:element_type, based_on.element_type), :graph => based_on.graph, :wrapper => based_on.wrapper, :extensions => based_on.extensions, :info => based_on.info)
      else
        graph = opts[:graph] if opts[:graph]
        Pacer::Route.new(:source => source, :element_type => opts.fetch(:element_type, :object), :graph => graph, :wrapper => opts[:wrapper], :extensions => opts[:extensions], :info => opts[:info])
      end
    end
  end

  def id_to_element_route(args = {})
    based_on = args[:based_on]
    raise 'Must supply :based_on option' unless based_on
    raise 'Graph routes do not contain element ids to look up' if self.is_a? Pacer::Core::Route and graph
    raise 'Based on route must be a graph route' unless based_on.graph
    r = to_route(:info => "#{ count } ids")
    r.chain_route(:graph => based_on.graph,
                  :element_type => based_on.element_type,
                  :pipe_class => based_on.send(:id_pipe_class),
                  :pipe_args => [based_on.graph],
                  :route_name => 'lookup',
                  :extensions => based_on.extensions,
                  :wrapper => based_on.wrapper,
                  :info => [args[:name], based_on.info].compact.join(':')).is_not(nil)
  end

  def group_count
    result = Hash.new(0)
    if block_given?
      each { |e| result[yield(e)] += 1 }
    else
      each { |e| result[e] += 1 }
    end
    result
  end

end
