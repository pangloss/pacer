require 'parslet'

module Pacer
  module Filter
    module ExpressionFilter
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
    end
  end
end
