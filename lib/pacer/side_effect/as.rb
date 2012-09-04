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
      class AsPipe < Pacer::Pipes::AbstractPipe

        field_reader :starts
        attr_accessor :vars

        def initialize(pipe, vars, variable_name)
          super()
          setStarts pipe if pipe
          @vars = vars
          @variable_name = variable_name
        end

        def getCurrentPath
          starts.getCurrentPath
        end

        protected

        def processNextStart
          @vars[@variable_name] = starts.next
        end
      end


      import java.util.HashSet

      attr_accessor :variable_name

      protected

      def attach_pipe(pipe)
        if element_type == :vertex or element_type == :edge or element_type == :mixed
          wrapped = Pacer::Pipes::WrappingPipe.new graph, element_type, extensions
          wrapped.setStarts pipe
          as_pipe = AsPipe.new(wrapped, vars, variable_name)
          unwrapped = Pacer::Pipes::UnwrappingPipe.new
          unwrapped.setStarts as_pipe
          unwrapped
        else
          AsPipe.new(pipe, vars, variable_name)
        end
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
