module Pacer
  module Routes
    module RouteOperations
      def is(value)
        chain_route({ :filter => :object, :value => value })
      end

      def is_not(value)
        chain_route({ :filter => :object, :value => value, :negate => true })
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
    end
  end
end
