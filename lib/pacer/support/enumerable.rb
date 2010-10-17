# Extend the built-in Enumerable module:
module Enumerable

  # Transform the enumerable into a java HashSet.
  def to_hashset(method = nil, *args)
    hs = java.util.HashSet.new
    iter = self.each
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
end
