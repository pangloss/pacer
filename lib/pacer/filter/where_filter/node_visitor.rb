module Pacer
  module Filter
    module WhereFilter
      class NodeVisitor
        import com.tinkerpop.pipes.filter.OrFilterPipe
        import com.tinkerpop.pipes.filter.FilterPipe
        import com.tinkerpop.pipes.filter.AndFilterPipe
        import com.tinkerpop.pipes.filter.OrFilterPipe
        import com.tinkerpop.pipes.filter.ObjectFilterPipe
        import com.tinkerpop.pipes.transform.PropertyPipe
        import com.tinkerpop.pipes.transform.HasCountPipe
        NeverPipe = Pacer::Pipes::NeverPipe
        IdentityPipe = Pacer::Pipes::IdentityPipe
        PropertyComparisonFilterPipe = Pacer::Pipes::PropertyComparisonFilterPipe
        Pipeline = Pacer::Pipes::Pipeline

        Filters = {
          '==' => FilterPipe::Filter::EQUAL,
          '='  => FilterPipe::Filter::EQUAL,
          '!=' => FilterPipe::Filter::NOT_EQUAL,
          '>'  => FilterPipe::Filter::GREATER_THAN,
          '<'  => FilterPipe::Filter::LESS_THAN,
          '>=' => FilterPipe::Filter::GREATER_THAN_EQUAL,
          '<=' => FilterPipe::Filter::LESS_THAN_EQUAL
        }

        ReverseFilters = Filters.merge(
          '<'  => FilterPipe::Filter::GREATER_THAN,
          '>'  => FilterPipe::Filter::LESS_THAN,
          '<=' => FilterPipe::Filter::GREATER_THAN_EQUAL,
          '>=' => FilterPipe::Filter::LESS_THAN_EQUAL
        )

        class Pipe
          def initialize(pipe, *args)
            @pipe = pipe
            @args = args
          end

          attr_reader :pipe
          attr_reader :args

          def inspect(depth = 0)
            ([" " * depth + pipe.to_s] + args.map do |arg|
              if arg.is_a? Pipe or arg.is_a? Value
                arg.inspect(depth + 2)
              else
                " " * (depth + 2) + arg.to_s
              end
            end).join "\n"
          end

          def build
            pipe.new *build_args
          end

          def build_args
            args.map do |arg|
              if arg.is_a? Pipe
                arg.build
              elsif arg.is_a? Value
                arg.value
              else
                arg
              end
            end
          end
        end

        class Value
          def initialize(value)
            @value = value
          end

          def pipe; end
          attr_reader :value

          def inspect(depth = 0)
            " " * depth + value.inspect
          end

          def build
            value
          end
        end


        class << self

          def build_comparison(a, b, name)
            raise "Operation not supported: #{ name }" unless %w[ == != > < >= <= ].include? name
            if a.is_a? Value and b.is_a? Value
              if a.value.send name, b.value
                Pipe.new IdentityPipe
              else
                Pipe.new NeverPipe
              end
            elsif a.pipe == PropertyPipe and b.pipe == PropertyPipe
              Pipe.new PropertyComparisonFilterPipe, a, b, Filters[name]
            elsif b.pipe == PropertyPipe and a.is_a? Value
              Pipe.new Pipeline, b, Pipe.new(ObjectFilterPipe, a, ReverseFilters[name])
            else
              Pipe.new Pipeline, a, Pipe.new(ObjectFilterPipe, b, Filters[name])
            end
          end 

          def visitAndNode(node)
            a = node.first_node.accept(self)
            b = node.second_node.accept(self)

            if a.pipe == AndFilterPipe and b.pipe == AndFilterPipe
              Pipe.new AndFilterPipe, *a.args, *b.args
            elsif a.pipe == AndFilterPipe
              Pipe.new AndFilterPipe, *a.args, b
            elsif b.pipe == AndFilterPipe
              Pipe.new AndFilterPipe, a, *b.args
            else
              Pipe.new AndFilterPipe, a, b
            end
          end 

          def visitArrayNode(node)
            Value.new node.child_nodes.map { |n| n.accept self }
          end 

          def visitBignumNode(node)
            Value.new node.value.to_s
          end

          def visitCallNode(node)
            a = node.receiver_node.accept(self)
            if node.args_node
              b = node.args_node.accept(self).value.first
              build_comparison(a, b, node.name)
            else
              case node.name
              when '!'
                if a.is_a? Value
                  Value.new !a.value
                elsif a.pipe == PropertyPipe
                  raise 'Currently can not negate properties (need to implement a new pipe class)'
                else
                  Pipe.new(Pipeline, a, Pipe.new(HasCountPipe, -1, 0), Pipe.new(ObjectFilterPipe, true, Filters['==']))
                end
              when '-'
                if a.is_a? Value
                  Value.new -a.value
                else
                  raise 'Currently can not negate properties or pipes (need to implement a new pipe class)'
                end
              when '+'
                a
              else
                raise "Unknown operator #{ node.name } applied to (#{ a.inspect })"
              end
            end
          end

          def visitFalseNode(node)
            Pipe.new NeverPipe
          end 

          def visitFixnumNode(node)
            Value.new node.value
          end 

          def visitFloatNode(node)
            Value.new node.value
          end 

          def visitLocalAsgnNode(node)
            a = Pipe.new PropertyPipe, node.name
            b = node.value_node.accept(self)
            build_comparison(a, b, '==')
          end 

          def visitNewlineNode(node)
            node.next_node.accept(self)
          end 

          def visitNilNode(node)
            Value.new nil
          end 

          def visitOrNode(node)
            a = node.first_node.accept(self)
            b = node.second_node.accept(self)
            if a.pipe == OrFilterPipe and b.pipe == OrFilterPipe
              Pipe.new OrFilterPipe, *a.args, *b.args
            elsif a.pipe == OrFilterPipe
              Pipe.new OrFilterPipe, *a.args, b
            elsif b.pipe == OrFilterPipe
              Pipe.new OrFilterPipe, a, *b.args
            else
              Pipe.new OrFilterPipe, a, b
            end
          end 

          def visitRootNode(node)
            pipe = node.body_node.accept self
            if pipe.pipe == AndFilterPipe or pipe.pipe == OrFilterPipe
              pipe
            else
              Pipe.new AndFilterPipe, pipe
            end
          end 

          def visitStrNode(node)
            Value.new node.value
          end 

          def visitSymbolNode(node)
            Value.new node.name
          end 

          def visitTrueNode(node)
            Pipe.new IdentityPipe
          end 

          def visitVCallNode(node)
            Pipe.new PropertyPipe, node.name
          end 
        end
      end
    end
  end
end
