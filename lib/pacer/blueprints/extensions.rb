module Pacer
  # NOTE these extensions modules can only be included in classes that don't include the
  # default Java method aliases generated when importing Java classes into JRuby. In those
  # classes the methods must be copied and pasted in order to overwrite the aliased methods.
  module GraphExtensions
    def self.included(target)
      target.class_eval do
        include GraphMixin
        include GraphIndicesMixin if target.ancestors.include? com.tinkerpop.blueprints.pgm.IndexableGraph
        include Pacer::Core::Route
        include Pacer::Core::Graph::GraphRoute
        include Pacer::Core::Graph::GraphIndexRoute if target.ancestors.include? com.tinkerpop.blueprints.pgm.IndexableGraph
      end
    end
  end

  module VertexExtensions
    def self.included(target)
      target.class_eval do
        include Pacer::Core::Graph::VerticesRoute
        include ElementMixin
        include VertexMixin
      end
    end
  end

  module EdgeExtensions
    def self.included(target)
      target.class_eval do
        include Pacer::Core::Graph::EdgesRoute
        include ElementMixin
        include EdgeMixin
      end
    end

    def in_vertex(extensions = nil)
      v = inVertex
      v.graph = graph
      if extensions.is_a? Enumerable
        v.add_extensions extensions
      elsif extensions
        v.add_extensions [extensions]
      else
        v
      end
    end

    def out_vertex(extensions = nil)
      v = outVertex
      v.graph = graph
      if extensions.is_a? Enumerable
        v.add_extensions extensions
      elsif extensions
        v.add_extensions [extensions]
      else
        v
      end
    end
  end
end
