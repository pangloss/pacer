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
      attr_reader :exp, :parsed
      attr_accessor :args

      def exp=(str)
        @exp = str
        @parsed = Parser.parse str
      end

      protected

      def attach_pipe(end_pipe)
        end_pipe
      end

      remove_const 'Builder' if const_defined? 'Builder'

      class Builder < Parslet::Transform
        Filters = {
          '==' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::EQUAL,
          '='  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::EQUAL,
          '!=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::NOT_EQUAL,
          '>'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN,
          '<'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN,
          '>=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN_EQUAL,
          '<=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN_EQUAL
        }
        ReverseFilters = {
          '==' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::EQUAL,
          '='  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::EQUAL,
          '!=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::NOT_EQUAL,
          '<'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN,
          '>'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN,
          '<=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN_EQUAL,
          '>=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN_EQUAL
        }
        rule(:str => simple(:x)) { x }
        rule(:int => simple(:x)) { Integer(x) }
        rule(:float => simple(:x)) { Float(x) }
        rule(:bool => simple(:x)) { x == 'true' }

        rule(:statement => { :left => { :prop => simple(:property) },
                             :op => simple(:op),
                             :right => simple(:value) }
        ) do |h|
          prop_pipe = com.tinkerpop.pipes.pgm.PropertyPipe.new(h[:property])
          filter_pipe = com.tinkerpop.pipes.filter.ObjectFilterPipe.new(h[:value], Filters[h[:op]])
          filter_pipe.setStarts(prop_pipe)
          [prop_pipe, filter_pipe]
        end

        rule(:statement => { :left => simple(:value),
                             :op => simple(:op),
                             :right => { :prop => simple(:property) } }
        ) do |h|
          prop_pipe = com.tinkerpop.pipes.pgm.PropertyPipe.new(h[:property])
          filter_pipe = com.tinkerpop.pipes.filter.ObjectFilterPipe.new(h[:value], ReverseFilters[h[:op]])
          filter_pipe.setStarts(prop_pipe)
          [prop_pipe, filter_pipe]
        end

        rule(:statement => { :left => simple(:left),
                             :op => simple(:op),
                             :right => simple(:right) }
        ) do
          result = case op
          when '=', '==' ; left == right
          when '>'       ; left > right
          when '>='      ; left >= right
          when '<'       ; left < right
          when '<='      ; left <= right
          when '!='      ; left != right
          else
            raise "Unrecognized operator #{ op }"
          end
          if result
            pipe = Pacer::Pipes::TruePipe.new
          else
            pipe = Pacer::Pipes::FalsePipe.new
          end
          [pipe, pipe]
        end
      end

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
        rule(:boolean)   { ( match('true') | match('false') ).as(:bool) >> space? }
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
        rule(:negate)     { (str('not') | str('!')).as(:negate).maybe >> space? }

        rule(:statement)  { (negate >> ( data.as(:left) >> comparison >> data.as(:right) | proc_variable )).as(:statement) >> space? }
        rule(:group)      { (negate >> lparen >> expression >> rparen).as(:group) >> space? }
        rule(:and_group)  { ((statement | group) >> (bool_and >> (statement | group)).repeat(1) >> or_group.maybe).as(:and) }
        rule(:or_group)   { ((bool_or >> (and_group | group | statement)).repeat(1)).as(:or) >> space? }
        rule(:expression) { (and_group | group | statement) >> or_group.maybe }

        root :expression
      end
    end
  end
end
