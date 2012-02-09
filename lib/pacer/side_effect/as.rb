module Pacer
  module Routes::RouteOperations
    # Store the current intermediate element in the route's vars hash by the
    # given name so that it is accessible subsequently in the processing of the
    # route.
    def as(name)
      as = ::Pacer::SideEffect::As
      section(name, as::SingleElementSet).chain_route :side_effect => as, :variable_name => name
    end
  end

  module SideEffect
    module As
      attr_accessor :variable_name

      def root?
        false
      end

      protected

      def attach_pipe(pipe)
        Pacer::Pipes::VariableStoreIteratorWrapper.new(pipe, vars, @variable_name)
      end

      def has_routable_class?
        false
      end

      def inspect_class_name
        @variable_name.inspect
      end

      class SingleElementSet < HashSet
        def on_element(element)
          clear
          add element
        end

        def reset
          clear
        end
      end
    end
  end
end
