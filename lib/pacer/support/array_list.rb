java.util.ArrayList
class Java::JavaUtil::ArrayList
  def inspect
    to_a.inspect
  end
end

require 'set'
java.util.HashSet
class Java::JavaUtil::HashSet
  def inspect
    to_set.inspect
  end
end
