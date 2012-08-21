require 'forwardable'

module Pacer
  def self.vertex_wrapper(*exts)
    Wrappers::VertexWrapper.wrapper_for(exts)
  end

  def self.edge_wrapper(*exts)
    Wrappers::EdgeWrapper.wrapper_for(exts)
  end

  module Wrappers
  end
end

require 'pacer/wrappers/new_element'
require 'pacer/wrappers/element_wrapper'
require 'pacer/wrappers/vertex_wrapper'
require 'pacer/wrappers/edge_wrapper'
require 'pacer/wrappers/index_wrapper'
require 'pacer/wrappers/wrapper_selector'
require 'pacer/wrappers/wrapping_pipe_function'
