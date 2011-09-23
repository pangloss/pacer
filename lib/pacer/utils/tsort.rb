require 'tsort'

module Pacer
  module Utils
    # Include this module in your traversal to use ruby's built-in TSort
    # utility to sort your vertices according to the direction of the
    # edges that connect them.
    module TSort
      module Route
        include ::TSort

        attr_accessor :tsort_anon_mod

        # NOTE: this is a great example of dynamically injecting a custom method
        # into a route.
        def dependencies(&block)
          anon_mod = Module.new
          anon_mod.const_set :Route, TSort::Route
          anon_mod.const_set :Vertex, Module.new
          anon_mod::Vertex.const_set :DependenciesBlock, block
          anon_mod::Vertex.instance_eval do
            def self.included(target)
              target.const_set :DependenciesBlock, self::DependenciesBlock
            end
          end
          route = v(*(extensions - [TSort] + [anon_mod]))
          route.tsort_anon_mod = anon_mod
          route
        end

        def tsort_each_node
          v.each do |vertex|
            yield vertex
          end
        end

        def tsort_each_child(node)
          node.tsort_dependencies(tsort_anon_mod).each do |vertex|
            yield vertex
          end
        end

        def tsort
          super.to_route(:graph => graph,
                         :element_type => :vertex,
                         :extensions => (extensions - [TSort, tsort_anon_mod]))
        end
      end

      module Vertex
        def tsort_each_node
          yield self
        end

        def tsort_dependencies(tsort_anon_mod = nil)
          if self.class.const_defined? :DependenciesBlock
            self.class::DependenciesBlock.call(self).add_extension(tsort_anon_mod)
          else
            self.in
          end
        end
      end
    end
  end
end
