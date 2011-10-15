require 'pacer/filter/expression_filter/parser'
require 'pacer/filter/expression_filter/builder'

module Pacer
  module Routes
    module RouteOperations
      def where(str, vars = {})
        chain_route :filter => :expression, :where_statement => str, :vars => vars
      end
    end
  end

  module Filter
    module ExpressionFilter
      attr_reader :where_statement, :parsed
      attr_accessor :vars

      def where_statement=(str)
        @where_statement = str
        @built = @parsed = nil
      end

      def parsed
        @parsed ||= Parser.parse @where_statement
      end

      def build!
        @built ||= Builder.build(parsed, self, vars)
      end

      protected

      def attach_pipe(end_pipe)
        pipe = build!
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        "where(#@where_statement)"
      end
    end
  end
end
