module Pacer
  module Routes
    module RouteOperations
      def is(value)
        if value.is_a? Symbol
          chain_route :filter => :property, :block => proc { |v| v.vars[value] == v }
        else
          chain_route({ :filter => :object, :value => value })
        end
      end

      def is_not(value)
        if value.is_a? Symbol
          chain_route :filter => :property, :block => proc { |v| v.vars[value] != v }
        else
          chain_route({ :filter => :object, :value => value, :negate => true })
        end
      end
    end
  end

  module Filter
    module ObjectFilter
      import com.tinkerpop.pipes.filter.ObjectFilterPipe

      attr_accessor :value, :negate

      protected

      def attach_pipe(end_pipe)
        pipe = ObjectFilterPipe.new(value, negate ? Pacer::Pipes::NOT_EQUAL : Pacer::Pipes::EQUAL)
        pipe.set_starts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        if negate
          "is_not(#{ value.inspect })"
        else
          "is(#{ value.inspect })"
        end
      end
    end
  end
end
