require 'parslet'

module Parslet
  class Transform
    public :simple, :sequence
  end
end

module Pacer
  module Filter
    module ExpressionFilter
      remove_const 'Builder' if const_defined? 'Builder'

      import com.tinkerpop.pipes.filter.OrFilterPipe
      import com.tinkerpop.pipes.filter.FilterPipe
      import com.tinkerpop.pipes.filter.AndFilterPipe
      import com.tinkerpop.pipes.filter.OrFilterPipe
      import com.tinkerpop.pipes.filter.ObjectFilterPipe

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
          OrFilterPipe.new(*@pipes)
        end
      end

      class Builder
        # These are defined with counterintuitive meanings so all meanings must be reversed.
        Filters = {
          '==' => FilterPipe::Filter::EQUAL,
          '='  => FilterPipe::Filter::EQUAL,
          '!=' => FilterPipe::Filter::NOT_EQUAL,
          '>'  => FilterPipe::Filter::GREATER_THAN,
          '<'  => FilterPipe::Filter::LESS_THAN,
          '>=' => FilterPipe::Filter::GREATER_THAN_EQUAL,
          '<=' => FilterPipe::Filter::LESS_THAN_EQUAL
        }

        # Further adjust to swap the order of the parameters...?
        # TODO: This was either undone or done wrong before. I need to do some
        # sanity tests and verify the unit tests here
        ReverseFilters = Filters

        class << self
          def build(tree, route, vars)
            @builder ||= new
            pipe = @builder.apply(tree, route, vars)
            case pipe
            when AndFilterPipe, OrFilterPipe
              pipe
            else
              AndFilterPipe.new(pipe)
            end
          end
        end

        def initialize(vars = {})
          @vars = vars
          build_transform
        end

        def apply(tree, route, vars = nil)
          @vars = Hash[vars.map { |k, v| [k.to_s, v] }] if vars
          @route = route
          @transform.apply tree
        end

        protected

        def pipeline(name, *pipes)
          pipe = Pacer::Pipes::Pipeline.new *pipes
          if Pacer.debug_pipes
            if name.is_a? Hash
              Pacer.debug_pipes << name.merge(:pipeline => pipes, :end => pipe)
            else
              Pacer.debug_pipes << { :name => name, :pipeline => pipes, :end => pipe }
            end
          end
          pipe
        end

        def val(value)
          if value.is_a? Parslet::Slice
            value.to_s
          else
            value
          end
        end

        def build_transform
          @transform = t = Parslet::Transform.new
          t.rule(:var => t.simple(:x)) do |h|
            var = @vars[val(h[:x])]
            if var.is_a? Fixnum
              java.lang.Long.new var
            elsif var.is_a? Numeric
              java.lang.Double.new var
            else
              var
            end
          end

          t.rule(:str => t.simple(:x)) { x }
          t.rule(:int => t.simple(:x)) do |h|
            java.lang.Long.new Integer(val(h[:x]))
          end
          t.rule(:float => t.simple(:x)) { java.lang.Double.new Float(x) }
          t.rule(:bool => t.simple(:x)) { x == 'true' }
          t.rule(:null => t.simple(:x)) { nil }

          t.rule(:statement => true) do |h|
            pipeline 'true', Pacer::Pipes::IdentityPipe.new
          end
          t.rule(:statement => false) do |h|
            pipeline 'false', Pacer::Pipes::NeverPipe.new
          end
          t.rule(:statement => { :proc => t.simple(:name) }) do |h|
            pipeline h.inspect, Pacer::Pipes::BlockFilterPipe.new(@route, @vars[val(h[:name])])
          end

          t.rule(:statement => { :left => { :prop => t.simple(:property) }, :op => t.simple(:op), :right => t.simple(:value) }) do |h|
            prop_pipe = Pacer::Pipes::PropertyPipe.new(val(h[:property]))
            filter_pipe = ObjectFilterPipe.new(val(h[:value]), Filters[val(h[:op])])
            pipeline h.inspect, prop_pipe, filter_pipe
          end

          t.rule(:statement => { :left => { :prop => t.simple(:left) }, :op => t.simple(:op), :right => { :prop => t.simple(:right) } }) do |h|
            pipeline h.inspect, Pacer::Pipes::PropertyComparisonFilterPipe.new(val(h[:left]), val(h[:right]), Filters[val(h[:op])])
          end

          t.rule(:statement => { :left => t.simple(:value), :op => t.simple(:op), :right => { :prop => t.simple(:property) } }) do |h|
            prop_pipe = Pacer::Pipes::PropertyPipe.new(val(h[:property]))
            filter_pipe = ObjectFilterPipe.new(val(h[:value]), ReverseFilters[val(h[:op])])
            pipeline h.inspect, prop_pipe, filter_pipe
          end

          t.rule(:statement => { :left => t.simple(:left), :op => t.simple(:op), :right => t.simple(:right) }) do |h|
            result = case val(h[:op])
            when '=', '==' ; h[:left] == h[:right]
            when '>'       ; h[:left] > h[:right]
            when '>='      ; h[:left] >= h[:right]
            when '<'       ; h[:left] < h[:right]
            when '<='      ; h[:left] <= h[:right]
            when '!='      ; h[:left] != h[:right]
            else
              raise "Unrecognized operator #{ h[:op] }"
            end
            if result
              pipeline h.inspect, Pacer::Pipes::IdentityPipe.new
            else
              pipeline h.inspect, Pacer::Pipes::NeverPipe.new
            end
          end

          t.rule(:group => t.simple(:x)) { x }

          t.rule(:or => t.sequence(:pipes)) do |h|
            pipes = h[:pipes]
            pipeline({ :name => 'or', :or => h[:pipes], :or_ends => pipes }, OrFilterPipe.new(*pipes))
          end

          t.rule(:and => t.sequence(:pipes)) do |h|
            pipes = h[:pipes]
            pipeline({ :name => 'and', :and => h[:pipes], :and_ends => pipes }, AndFilterPipe.new(*pipes))
          end

          t.rule(:not => t.simple(:pipe)) do |h|
            # TODO: this only negates matches, it doesn't negate non-matches because a non-match leaves nothing to negate!
            #       It must rather be done in the same way an AndFilterPipe is, where it controls the incoming element and tests the other pipe.
            pipes = []
            pipes << ObjectFilterPipe.new(true, Filters['!='])
            pipeline 'not', *pipes
          end
        end
      end
    end
  end
end
