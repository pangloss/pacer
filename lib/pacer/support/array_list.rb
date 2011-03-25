java.util.ArrayList
class Java::JavaUtil::ArrayList
  def inspect
    to_a.inspect
  end
end

java.util.LinkedList
class Java::JavaUtil::LinkedList
  def inspect
    to_a.inspect
  end
end

require 'set'
java.util.HashSet
class Java::JavaUtil::HashSet
  def inspect
    to_set.inspect.sub(/Set/, 'HashSet')
  end
end

java.util.HashMap
class Java::JavaUtil::HashMap
  def to_hash_map
    self
  end
end
