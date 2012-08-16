module Pacer
  import com.tinkerpop.blueprints.impls.tg.TinkerGraph
  import com.tinkerpop.blueprints.impls.tg.TinkerIndex

  # Create a new TinkerGraph. If path is given, use Tinkergraph in
  # its standard simple persistant mode.
  def self.tg(path = nil)
    if path
      PacerGraph.new TinkerGraph.new(path), SimpleEncoder
    else
      PacerGraph.new TinkerGraph.new, SimpleEncoder
    end
  end

  class TinkerIndex
    include IndexMixin
  end
end
