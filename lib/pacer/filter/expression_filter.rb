require 'pacer/filter/expression_filter/parser'
require 'pacer/filter/expression_filter/builder'

module Pacer
  module Routes
    module RouteOperations
      def where(str, vars = {})
        chain_route :filter => :expression, :where => str, :vars => vars
      end
    end
  end

  module Filter
    module ExpressionFilter
      attr_reader :where, :parsed
      attr_accessor :vars

      def where=(str)
        @where = str
        @parsed = Parser.parse str
      end

      def build!
        Builder.build(parsed, self, vars)
      end

      protected

      def attach_pipe(end_pipe)
        pipe = build!
        pipe.setStarts end_pipe
        pipe
      end
    end
  end
end
