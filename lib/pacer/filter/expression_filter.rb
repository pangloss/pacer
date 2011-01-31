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
        #rule(:boolean) { (str('and') | str('or')).as(:boolean) >> space? }
        rule(:bool_and) { str('and') >> space? }
        rule(:bool_or) { str('or') >> space? }
        rule(:data) { property | variable }
        rule(:negate) { str('not').as(:negate).maybe >> space? }

        rule(:statement) { (negate >> data.as(:left) >> comparison.as(:op) >> data.as(:right)).as(:statement) >> space? }
        rule(:group) { (negate >> lparen >> expression >> rparen).as(:group) >> space? }
        rule(:and_group) { ((statement | group) >> (bool_and >> (statement | group)).repeat(1) >> or_group.maybe).as(:and) }
        rule(:or_group) { ((bool_or >> (group | and_group | statement)).repeat(1)).as(:or) >> space? }
        rule(:expression) { (group | and_group | statement) >> or_group.maybe }
        #rule(:expression) { (group | statement) >> (boolean >> (group | statement)).repeat }

        root :expression

        #a = b or (c = d and e = f)
      end
    end
  end
end
