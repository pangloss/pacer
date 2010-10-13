# Extend the built-in Enumerable module:
module Enumerable

  # Transform the enumerable into a java HashSet.
  def to_hashset
    inject(java.util.HashSet.new) { |hs, e| hs.add e; hs }
  end
end
