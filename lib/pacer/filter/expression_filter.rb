require 'pacer/filter/expression_filter/parser'
require 'pacer/filter/expression_filter/builder'

module Parslet
  class Transform
    public :simple, :sequence
  end
end

module Pacer
  module Routes
    module RouteOperations
      def exp(str, vars = {})
        chain_route :filter => :expression, :exp => str, :vars => vars
      end
    end
  end

  module Filter
    module ExpressionFilter
      attr_reader :exp, :parsed
      attr_accessor :vars

      def exp=(str)
        @exp = str
        @parsed = Parser.parse str
      end

      def build!
        Builder.build(parsed, self, vars)
      end

      protected

      def attach_pipe(end_pipe)
        pipe = com.tinkerpop.pipes.filter.AndFilterPipe.new build!
        pipe.setStarts end_pipe
        pipe
      end
    end
  end
end
