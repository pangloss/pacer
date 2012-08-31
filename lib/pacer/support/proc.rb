class Proc
  def to_route(opts = {})
    based_on = opts[:based_on]
    if opts[:unwrap] or based_on and based_on.extensions and based_on.graph
      source = proc { self.call.map { |e| e.element } }
    else
      source = self
    end
    if based_on
      Pacer::RouteBuilder.current.chain(source, :element_type => :mixed, :graph => based_on.graph, :extensions => based_on.extensions, :info => based_on.info)
    else
      graph = opts[:graph] if opts[:graph]
      Pacer::RouteBuilder.current.chain(source, :element_type => (opts[:element_type] || :object), :graph => graph, :extensions => opts[:extensions], :info => opts[:info])
    end
  end
end
