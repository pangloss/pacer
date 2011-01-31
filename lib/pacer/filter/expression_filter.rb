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

        rule(:integer)    { match('[0-9]').repeat(1).as(:int) >> space? }
        rule(:float)      { (match('[0-9]').repeat(1) >> str('.') >> match('[0-9]').repeat(1) ).as(:float) >> space? }
        rule(:dq_string) { (str('"') >> ( str('\\') >> any | str('"').absnt? >> any ).repeat.as(:string) >> str('"')).as(:string) >> space? }
        rule(:sq_string) { (str("'") >> ( str('\\') >> any | str("'").absnt? >> any ).repeat.as(:string) >> str("'")).as(:string) >> space? }
        rule(:string)    { dq_string | sq_string }

        rule(:property_string) { (str("{") >> ( str('\\') >> any | str("}").absnt? >> any ).repeat.as(:property) >> str("}")) >> space? }

        rule(:identifier) { match['[a-zA-Z]'] >> match('[a-zA-Z0-9_]').repeat }
        rule(:variable) { str(':') >> identifier.as(:variable) >> space? }
        rule(:arguments) { lparen >> (identifier.as(:argument) >> space? >> (str(',') >> space? >> identifier.as(:argument) >> space?).repeat).maybe >> rparen }
        rule(:proc_variable) { str('&') >> identifier.as(:proc) >> arguments.maybe >> space? }

        rule(:property) { identifier.as(:property) >> space? }

        rule(:comparison) { (str('!=') | str('>=') | str('<=') | match("[=><]")) >> space? }
        rule(:bool_and) { str('and') >> space? }
        rule(:bool_or) { str('or') >> space? }
        rule(:data) { variable | proc_variable | property | property_string | integer | float | string }
        rule(:negate) { str('not').as(:negate).maybe >> space? }

        rule(:statement) { (negate >> ( data.as(:left) >> comparison.as(:op) >> data.as(:right) | proc_variable )).as(:statement) >> space? }
        rule(:group) { (negate >> lparen >> expression >> rparen).as(:group) >> space? }
        rule(:and_group) { ((statement | group) >> (bool_and >> (statement | group)).repeat(1) >> or_group.maybe).as(:and) }
        rule(:or_group) { ((bool_or >> (and_group | group | statement)).repeat(1)).as(:or) >> space? }
        rule(:expression) { (and_group | group | statement) >> or_group.maybe }

        root :expression

        #a = b or (c = d and e = f)
      end
    end
  end
end
