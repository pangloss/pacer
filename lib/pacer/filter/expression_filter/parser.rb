require 'parslet'

module Pacer
  module Filter
    module ExpressionFilter
      class Parser < Parslet::Parser
        class << self
          def reset
            @parser = nil
          end

          def parse(str)
            @parser ||= new
            @parser.parse str
          end
        end

        rule(:lparen)    { str('(') >> space? }
        rule(:rparen)    { str(')') >> space? }
        rule(:space)     { match('\s').repeat(1) }
        rule(:space?)    { space.maybe }

        rule(:integer)   { match('[0-9]').repeat(1).as(:int) >> space? }
        rule(:float)     { (match('[0-9]').repeat(1) >> str('.') >> match('[0-9]').repeat(1) ).as(:float) >> space? }
        rule(:boolean)   { ( str('true') | str('false') ).as(:bool) >> space? }
        rule(:dq_string) { (str('"') >> ( str('\\') >> any | str('"').absnt? >> any ).repeat.as(:str) >> str('"')) >> space? }
        rule(:sq_string) { (str("'") >> ( str('\\') >> any | str("'").absnt? >> any ).repeat.as(:str) >> str("'")) >> space? }
        rule(:string)    { dq_string | sq_string }

        rule(:property_string) { (str("{") >> ( str('\\') >> any | str("}").absnt? >> any ).repeat.as(:prop) >> str("}")) >> space? }

        rule(:identifier)      { match['[a-zA-Z]'] >> match('[a-zA-Z0-9_]').repeat }
        rule(:variable)        { str(':') >> identifier.as(:var) >> space? }
        rule(:proc_variable)   { str('&') >> identifier.as(:proc) >> space? }

        rule(:property)   { identifier.as(:prop) >> space? }

        rule(:comparison) { (str('!=') | str('>=') | str('<=') | str('==') | match("[=><]")).as(:op) >> space? }
        rule(:bool_and)   { str('and') >> space? }
        rule(:bool_or)    { str('or') >> space? }
        rule(:data)       { boolean | variable | proc_variable | property | property_string | float | integer | string }
        rule(:negate)     { (str('not') | str('!')) >> space? }

        rule(:statement)  { ( data.as(:left) >> comparison >> data.as(:right) | proc_variable | boolean ).as(:statement) }

        rule(:group)      { (lparen >> expression >> rparen).as(:group) >> space? }

        rule(:neg_expression)    { (negate >> (group | statement )).as(:not) }
        rule(:pos_expression)    {             group | statement }

        rule(:and_group)         { ((neg_expression | pos_expression) >> (bool_and >> (neg_expression | pos_expression)).repeat(1)).as(:and) }
        rule(:or_expression)     { (simple_expression                 >> (bool_or  >> simple_expression                ).repeat(1)).as(:or) }

        rule(:simple_expression) { and_group | neg_expression | pos_expression }
        rule(:expression)        { or_expression | simple_expression }

        root :expression
      end
    end
  end
end
