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
        # These are defined with counterintuitive meanings so all meanings must be reversed.
        Filters = {
          '==' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::NOT_EQUAL,
          '='  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::NOT_EQUAL,
          '!=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::EQUAL,
          '>'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN_EQUAL,
          '<'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN_EQUAL,
          '>=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN,
          '<=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN
        }

        # Further adjust to swap the order of the parameters.
        ReverseFilters = {
          '==' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::NOT_EQUAL,
          '='  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::NOT_EQUAL,
          '!=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::EQUAL,
          '<'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN_EQUAL,
          '>'  => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN_EQUAL,
          '<=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::GREATER_THAN,
          '>=' => com.tinkerpop.pipes.filter.ComparisonFilterPipe::Filter::LESS_THAN
        }

        class << self
          def build(tree, route, vars)
            @builder ||= new
            @builder.apply(tree, route, vars)
          end
        end

        def initialize(vars = {})
          @vars = vars
          build_transform
        end

        def apply(tree, route, vars = nil)
          @vars = vars if vars
          @route = route
          @transform.apply tree
        end

        protected

        def pipeline(name, *pipes)
          pipe = com.tinkerpop.pipes.Pipeline.new *pipes
          if Pacer.debug_pipes
            if name.is_a? Hash
              Pacer.debug_pipes << name.merge(:pipeline => pipes, :end => pipe)
            else
              Pacer.debug_pipes << { :name => name, :pipeline => pipes, :end => pipe }
            end
          end
          pipe
        end

        def build_transform
          @transform = t = Parslet::Transform.new
          t.rule(:var => t.simple(:x)) { |h| @vars[h[:x]] }

          t.rule(:str => t.simple(:x)) { x }
          t.rule(:int => t.simple(:x)) { Integer(x) }
          t.rule(:float => t.simple(:x)) { Float(x) }
          t.rule(:bool => t.simple(:x)) { x == 'true' }

          t.rule(:statement => true) do |h|
            pipeline 'true', Pacer::Pipes::IdentityPipe.new
          end
          t.rule(:statement => false) do |h|
            pipeline 'false', Pacer::Pipes::NeverPipe.new
          end
          t.rule(:statement => { :proc => t.simple(:name) }) do |h|
            pipeline h.inspect, Pacer::Pipes::BlockFilterPipe.new(@route, @vars[h[:name]])
          end

          t.rule(:statement => { :left => { :prop => t.simple(:property) }, :op => t.simple(:op), :right => t.simple(:value) }) do |h|
            prop_pipe = com.tinkerpop.pipes.pgm.PropertyPipe.new(h[:property])
            filter_pipe = com.tinkerpop.pipes.filter.ObjectFilterPipe.new(h[:value], Filters[h[:op]])
            pipeline h.inspect, prop_pipe, filter_pipe
          end

          t.rule(:statement => { :left => { :prop => t.simple(:left) }, :op => t.simple(:op), :right => { :prop => t.simple(:right) } }) do |h|
            pipeline h.inspect, Pacer::Pipes::PropertyComparisonFilterPipe.new(h[:left], h[:right], Filters[h[:op]])
          end

          t.rule(:statement => { :left => t.simple(:value), :op => t.simple(:op), :right => { :prop => t.simple(:property) } }) do |h|
            prop_pipe = com.tinkerpop.pipes.pgm.PropertyPipe.new(h[:property])
            filter_pipe = com.tinkerpop.pipes.filter.ObjectFilterPipe.new(h[:value], ReverseFilters[h[:op]])
            pipeline h.inspect, prop_pipe, filter_pipe
          end

          t.rule(:statement => { :left => t.simple(:left), :op => t.simple(:op), :right => t.simple(:right) }) do
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
              pipeline h.inspect, Pacer::Pipes::AlwaysPipe.new
            else
              pipeline h.inspect, Pacer::Pipes::NeverPipe.new
            end
          end

          t.rule(:group => t.simple(:x)) { x }

          t.rule(:or => t.sequence(:pipes)) do |h|
            pipes = h[:pipes].map { |p| com.tinkerpop.pipes.util.HasNextPipe.new(p) }
            pipeline({ :name => 'or', :or => h[:pipes], :or_ends => pipes }, com.tinkerpop.pipes.filter.OrFilterPipe.new(*pipes))
          end

          t.rule(:and => t.sequence(:pipes)) do |h|
            pipes = h[:pipes].map { |p| com.tinkerpop.pipes.util.HasNextPipe.new(p) }
            pipeline({ :name => 'and', :and => h[:pipes], :and_ends => pipes }, com.tinkerpop.pipes.filter.AndFilterPipe.new(*pipes))
          end

          t.rule(:not => t.simple(:pipe)) do |h|
            # TODO: negate incoming pipe
            Pacer.debug_pipes << { :name => '(not implemented)', :pipes => h[:pipe] } if Pacer.debug_pipes
            pipe
          end
        end
      end
    end
  end
end
