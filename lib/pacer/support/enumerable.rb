# Extend the built-in Enumerable module:
module Enumerable

  def one?
    counter = 0
    each do
      return false if counter == 1
      counter += 1
    end
    true
  end

  def many?
    counter = 0
    any? { if counter == 1; true; else; counter += 1; false; end }
  end

  # Transform the enumerable into a java HashSet.
  def to_hashset(method = nil, *args)
    return self if self.is_a? java.util.HashSet
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
    return hs
  rescue NativeException => e
    if (e.cause.kind_of?(java.util.NoSuchElementException))
      return hs
    else
      raise
    end
  end

  # NOTE: if this is a collection of wrapped vertices or edges, Java pipes
  # may crash with something like:
  #
  #   NativeException: java.lang.ClassCastException: org.jruby.RubyObject cannot be cast to com.tinkerpop.blueprints.pgm.Element
  #
  # You can work around that by passing the option :unwrap => true or
  # setting the :based_on parameter to a route that has extensions.
  def to_route(opts = {})
    if self.is_a? Pacer::Core::Route
      self
    else
      based_on = opts[:based_on]
      if opts[:unwrap] or based_on and based_on.extensions and based_on.graph
        source = proc { self.map { |e| e.element } }
      else
        source = self
      end
      if based_on
        Pacer::Route.new(:source => source, :element_type => :mixed, :graph => based_on.graph, :extensions => based_on.extensions, :info => based_on.info)
      else
        graph = opts[:graph] if opts[:graph]
        Pacer::Route.new(:source => source, :element_type => (opts[:element_type] || :object), :graph => graph, :extensions => opts[:extensions], :info => opts[:info])
      end
    end
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
