module Pacer
  import com.tinkerpop.blueprints.impls.tg.TinkerGraph

  # Create a new TinkerGraph. If path is given, use Tinkergraph in
  # its standard simple persistant mode.
  def self.tg(path = nil)
    if path
      PacerGraph.new SimpleEncoder, TinkerGraph.new(path)
    else
      PacerGraph.new SimpleEncoder, TinkerGraph.new
    end
  end
end
