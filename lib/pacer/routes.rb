module Pacer
  module Routes
    # Defines the Routes namespace
  end
end
require 'pacer/route/mixins'
require 'pacer/route/paths_route'
require 'pacer/route/branched_route'
require 'pacer/route/mixed_elements_route'
require 'pacer/route/invalid_route' # TODO: delete this one, it's not used.
require 'pacer/route/edges_route'
require 'pacer/route/vertices_route'
require 'pacer/route/vertex_variable_route'
require 'pacer/route/edge_variable_route'
require 'pacer/route/mixed_variable_route' #TODO: will need this one
require 'pacer/route/vertices_identity_route'
require 'pacer/route/edges_identity_route'
require 'pacer/route/mixed_identity_route'

