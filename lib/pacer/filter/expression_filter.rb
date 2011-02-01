require 'parslet'

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
        Builder.build(parsed, vars)
      end

      protected

      def attach_pipe(end_pipe)
        pipe = build!
        pipe.setStarts end_pipe
        pipe
      end

      remove_const 'Builder' if const_defined? 'Builder'

      class OrGroup
        def initialize(pipes = [])
          @pipes = pipes
        end

        def append(pipe)
          @pipes.push pipe
        end

        def prepend(pipe)
          @pipes.unshift pipe
        end

        def pipe
          com.tinkerpop.pipes.filter.OrFilterPipe.new(*@pipes)
        end
      end

      class Builder
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

        class << self
          def build(tree, vars)
            @builder ||= new
            @builder.apply(tree, vars)
          end
        end

        def initialize(vars = {})
          @vars = vars
          @transform = t = Parslet::Transform.new
          t.rule(:var => t.simple(:x)) { |h| @vars[h[:x]] }

          t.rule(:str => t.simple(:x)) { x }
          t.rule(:int => t.simple(:x)) { Integer(x) }
          t.rule(:float => t.simple(:x)) { Float(x) }
          t.rule(:bool => t.simple(:x)) { x == 'true' }

          t.rule(:statement => { :left => { :prop => t.simple(:property) },
                                 :op => t.simple(:op),
                                 :right => t.simple(:value) }
          ) do |h|
            prop_pipe = com.tinkerpop.pipes.pgm.PropertyPipe.new(h[:property])
            filter_pipe = com.tinkerpop.pipes.filter.ObjectFilterPipe.new(h[:value], Filters[h[:op]])
            com.tinkerpop.pipes.Pipeline.new prop_pipe, filter_pipe
          end

          t.rule(:statement => { :left => { :prop => t.simple(:left) },
                                 :op => t.simple(:op),
                                 :right => { :prop => t.simple(:right) } }
          ) do |h|
            Pacer::Pipes::PropertyComparisonFilterPipe.new(h[:left], h[:right], Filters[h[:op]])
          end
          t.rule(:statement => { :left => t.simple(:value),
                                 :op => t.simple(:op),
                                 :right => { :prop => t.simple(:property) } }
          ) do |h|
            prop_pipe = com.tinkerpop.pipes.pgm.PropertyPipe.new(h[:property])
            filter_pipe = com.tinkerpop.pipes.filter.ObjectFilterPipe.new(h[:value], ReverseFilters[h[:op]])
            com.tinkerpop.pipes.Pipeline.new prop_pipe, filter_pipe
          end

          t.rule(:statement => { :left => t.simple(:left),
                                 :op => t.simple(:op),
                                 :right => t.simple(:right) }
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
              Pacer::Pipes::TruePipe.new
            else
              Pacer::Pipes::FalsePipe.new
            end
          end

          t.rule(:group => t.simple(:x)) { x }
          t.rule(:group => t.simple(:group), :or => t.sequence(:or_pipes)) do |h|
            g = OrGroup.new h[:or_pipes]
            g.prepend h[:group]
            g.pipe
          end

          t.rule(:or => t.sequence(:pipes)) do |h|
            OrGroup.new h[:pipes]
          end

          t.rule(:and => t.sequence(:pipes)) do |h|
            or_group = h[:pipes].pop if h[:pipes].last.is_a? OrGroup
            and_pipe = com.tinkerpop.pipes.filter.AndFilterPipe.new *h[:pipes]
            if or_group
              or_group.prepend and_pipe
              or_group.pipe
            else
              and_pipe
            end
          end
        end

        def apply(tree, vars = nil)
          @vars = vars if vars
          @transform.apply tree
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
