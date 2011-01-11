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

  def to_route(opts = {})
    if self.is_a? Pacer::Core::Route
      self
    else
      r = Pacer::Routes::MixedElementsRoute.new(proc { select { |e| e.is_a? Pacer::ElementMixin } })
      r.pipe_class = nil
      if based_on = opts[:based_on]
        r.graph = based_on.graph
        r.add_extensions based_on.extensions
        r.info = based_on.info if based_on.info
      end
      r.add_extensions opts[:extensions] if opts[:extensions]
      r.graph = opts[:graph] if opts[:graph]
      r.info = opts[:info]
      r
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
