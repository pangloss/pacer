require 'parslet'

module Pacer
  module Routes
    module RouteOperations
      def exp(str, *args)
        chain_route :filter => :expression, :exp => str, :args => args
      end
    end
  end

  module Filter
    module ExpressionFilter
      attr_reader :exp
      attr_accessor :args

      def exp=(str)
      end

      protected

      def attach_pipe(end_pipe)
        
      end

      class Parser < Parslet::Parser
        rule(:lparen)     { str('(') >> space? }
        rule(:rparen)     { str(')') >> space? }
        rule(:space)      { match('\s').repeat(1) }
        rule(:space?)     { space.maybe }

        rule(:property) { match['[a-zA-Z]'] >> match('[a-zA-Z0-9_]').repeat >> space? }
        rule(:variable) { str('?') }

        rule(:comparison) { match("=|!=|/=|>|<|>=|<=") >> space? }
        rule(:boolean) { (str('and') | str('or')).as(:boolean) >> space? }
        rule(:data) { property | variable }

        rule(:statement) { (data.as(:left) >> comparison.as(:op) >> data.as(:right)).as(:statement) >> space? }
        rule(:group) { (lparen >> expression >> rparen).as(:group) >> space? }
        rule(:expression) { (group | statement) >> (boolean >> (group | statement)).repeat }

        root :expression
      end
    end
  end
end
