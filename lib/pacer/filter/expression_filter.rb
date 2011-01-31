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

        rule(:dq_string) { (str('"') >> ( str('\\') >> any | str('"').absnt? >> any).repeat.as(:string) >> str('"')).as(:string) >> space? }
        rule(:sq_string) { (str("'") >> ( str('\\') >> any | str("'").absnt? >> any).repeat.as(:string) >> str("'")).as(:string) >> space? }
        rule(:property_string)    { dq_string | sq_string }

        rule(:property) { match['[a-zA-Z]'] >> match('[a-zA-Z0-9_]').repeat >> space? }
        rule(:variable) { str('?') }

        rule(:comparison) { match("=|!=|/=|>|<|>=|<=") >> space? }
        rule(:boolean) { (str('and') | str('or')).as(:boolean) >> space? }
        rule(:data) { property | variable }
        rule(:negate) { str('not').as(:negate).maybe >> space? }

        rule(:statement) { (negate >> data.as(:left) >> comparison.as(:op) >> data.as(:right)).as(:statement) >> space? }
        rule(:group) { (negate >> lparen >> expression >> rparen).as(:group) >> space? }
        rule(:bool_statement) { (statement | group) >> (boolean >> expression).as(:next) }
        rule(:expression) { group | bool_statement | statement }
        #rule(:expression) { (group | statement) >> (boolean >> (group | statement)).repeat }

        root :expression

      end
    end
  end
end
