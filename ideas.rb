class Server
  include Vertex
end

class Application
  include Vertex
end

def pacer_syntax
  path = Path.new(graph)
  vertexes = path.vertexes
  vertexes == Path.new(path.vertexes)
  path.edges == Path.new(path.edges)
  vertexes.out_e(:instance).in_v

  gdc_applications = vertexes.in_e(:instance).out_v(Server).in_e.out_v(Application, :name => /^GDC/)

  # returns vertexes
  Path.vertex_path(:gdc_apps) { |path| path.vertexes(Server).in_e.out_v(Application, :group => 'GDC') }

  # returns edges
  Path.vertex_path(:contains) { |path| path.out_e(:contains) }

  Path.edge_path(:gdc_apps) { |path| path.edges(:contains).in_v(Application) }

  # Recursive path with support for edges and vertexes and branching
  # when recursing, return the deepest result that has a match
  Path.path(:parent_apps) do |path|
    path.max_depth(10)
    path.edge_path do |path|
      # recurse in as a vertex
      path.edges.both_v.parent_apps
    end
    path.vertex_path(Server) { |path| path.in_e.out_v(Application) }
    path.vertex_path(Server) { |path| path.in_e.out_v(Application).parent_apps }
    path.vertex_path(Application) { |path| path.in_e.out_v(Application) }
    path.vertex_path(Application) { |path| path.in_e.out_v(Application).parent_apps }
    path.vertex_path do |path|
      path.not(Application).not(Server).in_e.out_v.parent_apps
    end
  end

  # this is using a vertex_path
  # note that the block is not the function. The block filters then a normal
  gdc_blogs = vertexes.gdc_apps(:name => /blog/)

  # this is using an edge_path
  gdc_blogs.out_e.gdc_apps

  vertexes(Server).parent_apps

  # inline filter procs
  # uses the same path object as the normal expressions and as path
  # definitions, except it is defined for just the current edge or vertex. The
  # block must return true of false. If false, the vertex or element will not
  # be included in the results.
  vertexes.out_e.in_v { |path| path.out_e(:some_label).count == 2 }.out_e
end

  
