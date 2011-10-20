Pacer::Filter::WhereFilter::NodeVisitor
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
        end
        
        def build_comparison(a, b, name)
          if a.pipe == PropertyPipe and b.pipe == PropertyPipe
            Pipe.new PropertyComparisonFilterPipe, a, b, Filters[name]
          end
          if b.pipe == PropertyPipe and a.is_a? Value
            Pipe.new Pipeline, b, Pipe.new(ObjectFilterPipe, a, ReverseFilters[name])
          else
            Pipe.new Pipeline, a, Pipe.new(ObjectFilterPipe, b, Filters[name])
          end
        end 

        def visitAliasNode(node)
          puts "visitAliasNode"
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

        def visitArgsCatNode(node)
          puts "visitArgsCatNode"
        end 

        def visitArgsNode(node)
          puts "visitArgsNode"
        end 

        def visitArgsPushNode(node)
          puts "visitArgsPushNode"
        end 

        def visitArrayNode(node)
          Value.new node.child_nodes.map { |n| n.accept self }
        end 

        def visitAttrAssignNode(node)
          puts "visitAttrAssignNode"
        end 

        def visitBackRefNode(node)
          puts "visitBackRefNode"
        end 

        def visitBeginNode(node)
          puts "visitBeginNode"
        end 

        def visitBignumNode(node)
          puts "visitBignumNode"
        end 

        def visitBlockArg18Node(node)
          puts "visitBlockArg18Node"
        end 

        def visitBlockArgNode(node)
          puts "visitBlockArgNode"
        end 

        def visitBlockNode(node)
          puts "visitBlockNode"
        end 

        def visitBlockPassNode(node)
          puts "visitBlockPassNode"
        end 

        def visitBreakNode(node)
          puts "visitBreakNode"
        end 

        def visitCallNode(node)
          a = node.receiver_node.accept(self)
          b = node.args_node.accept(self).value.first
          build_comparison(a, b, node.name)
        end

        def visitCaseNode(node)
          puts "visitCaseNode"
        end 

        def visitClassNode(node)
          puts "visitClassNode"
        end 

        def visitClassVarAsgnNode(node)
          puts "visitClassVarAsgnNode"
        end 

        def visitClassVarDeclNode(node)
          puts "visitClassVarDeclNode"
        end 

        def visitClassVarNode(node)
          puts "visitClassVarNode"
        end 

        def visitColon2Node(node)
          puts "visitColon2Node"
        end 

        def visitColon3Node(node)
          puts "visitColon3Node"
        end 

        def visitConstDeclNode(node)
          puts "visitConstDeclNode"
        end 

        def visitConstNode(node)
          puts "visitConstNode"
        end 

        def visitDAsgnNode(node)
          puts "visitDAsgnNode"
        end 

        def visitDefinedNode(node)
          puts "visitDefinedNode"
        end 

        def visitDefnNode(node)
          puts "visitDefnNode"
        end 

        def visitDefsNode(node)
          puts "visitDefsNode"
        end 

        def visitDotNode(node)
          puts "visitDotNode"
        end 

        def visitDRegxNode(node)
          puts "visitDRegxNode"
        end 

        def visitDStrNode(node)
          puts "visitDStrNode"
        end 

        def visitDSymbolNode(node)
          puts "visitDSymbolNode"
        end 

        def visitDVarNode(node)
          puts "visitDVarNode"
        end 

        def visitDXStrNode(node)
          puts "visitDXStrNode"
        end 

        def visitEncodingNode(node)
          puts "visitEncodingNode"
        end 

        def visitEnsureNode(node)
          puts "visitEnsureNode"
        end 

        def visitEvStrNode(node)
          puts "visitEvStrNode"
        end 

        def visitFalseNode(node)
          Pipe.new NeverPipe
        end 

        def visitFCallNode(node)
          puts "visitFCallNode"
        end 

        def visitFixnumNode(node)
          Value.new node.value
        end 

        def visitFlipNode(node)
          puts "visitFlipNode"
        end 

        def visitFloatNode(node)
          Value.new node.value
        end 

        def visitForNode(node)
          puts "visitForNode"
        end 

        def visitGlobalAsgnNode(node)
          puts "visitGlobalAsgnNode"
        end 

        def visitGlobalVarNode(node)
          puts "visitGlobalVarNode"
        end 

        def visitHashNode(node)
          puts "visitHashNode"
        end 

        def visitIfNode(node)
          puts "visitIfNode"
        end 

        def visitInstAsgnNode(node)
          puts "visitInstAsgnNode"
        end 

        def visitInstVarNode(node)
          puts "visitInstVarNode"
        end 

        def visitIterNode(node)
          puts "visitIterNode"
        end 

        def visitLambdaNode(node)
          puts "visitLambdaNode"
        end 

        def visitLiteralNode(node)
          puts "visitLiteralNode"
        end 

        def visitLocalAsgnNode(node)
          a = Pipe.new PropertyPipe, node.name
          b = node.value_node.accept(self)
          build_comparison(a, b, '==')
        end 

        def visitLocalVarNode(node)
          puts "visitLocalVarNode"
        end 

        def visitMatch2Node(node)
          puts "visitMatch2Node"
        end 

        def visitMatch3Node(node)
          puts "visitMatch3Node"
        end 

        def visitMatchNode(node)
          puts "visitMatchNode"
        end 

        def visitModuleNode(node)
          puts "visitModuleNode"
        end 

        def visitMultipleAsgnNode(node)
          puts "visitMultipleAsgnNode"
        end 

        def visitMultipleAsgnNode(node)
          puts "visitMultipleAsgnNode"
        end 

        def visitNewlineNode(node)
          node.next_node.accept(self)
        end 

        def visitNextNode(node)
          puts "visitNextNode"
        end 

        def visitNilNode(node)
          nil
        end 

        def visitNotNode(node)
          puts "visitNotNode"
          # TODO: this only negates matches, it doesn't negate non-matches because a non-match leaves nothing to negate!
          #       It must rather be done in the same way an AndFilterPipe is, where it controls the incoming element and tests the other pipe.
          #pipeline 'not', ObjectFilterPipe.new(true, Filters['!='])
        end 

        def visitNthRefNode(node)
          puts "visitNthRefNode"
        end 

        def visitOpAsgnAndNode(node)
          puts "visitOpAsgnAndNode"
        end 

        def visitOpAsgnNode(node)
          puts "visitOpAsgnNode"
        end 

        def visitOpAsgnOrNode(node)
          puts "visitOpAsgnOrNode"
        end 

        def visitOpElementAsgnNode(node)
          puts "visitOpElementAsgnNode"
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

        def visitPostExeNode(node)
          puts "visitPostExeNode"
        end 

        def visitPreExeNode(node)
          puts "visitPreExeNode"
        end 

        def visitRedoNode(node)
          puts "visitRedoNode"
        end 

        def visitRegexpNode(node)
          puts "visitRegexpNode"
        end 

        def visitRescueBodyNode(node)
          puts "visitRescueBodyNode"
        end 

        def visitRescueNode(node)
          puts "visitRescueNode"
        end 

        def visitRestArgNode(node)
          puts "visitRestArgNode"
        end 

        def visitRetryNode(node)
          puts "visitRetryNode"
        end 

        def visitReturnNode(node)
          puts "visitReturnNode"
        end 

        def visitRootNode(node)
          node.body_node.accept self
        end 

        def visitSClassNode(node)
          puts "visitSClassNode"
        end 

        def visitSelfNode(node)
          puts "visitSelfNode"
        end 

        def visitSplatNode(node)
          puts "visitSplatNode"
        end 

        def visitStrNode(node)
          Value.new node.value
        end 

        def visitSuperNode(node)
          puts "visitSuperNode"
        end 

        def visitSValueNode(node)
          puts "visitSValueNode"
        end 

        def visitSymbolNode(node)
          Value.new node.name
        end 

        def visitToAryNode(node)
          puts "visitToAryNode"
        end 

        def visitTrueNode(node)
          Pipe.new IdentityPipe
        end 

        def visitUndefNode(node)
          puts "visitUndefNode"
        end 

        def visitUntilNode(node)
          puts "visitUntilNode"
        end 

        def visitVAliasNode(node)
          puts "visitVAliasNode"
        end 

        def visitVCallNode(node)
          #puts "vcal child nodes should be empty: #{ node.child_nodes.inspect }"
          Pipe.new PropertyPipe, node.name
        end 

        def visitWhenNode(node)
          puts "visitWhenNode"
        end 

        def visitWhileNode(node)
          puts "visitWhileNode"
        end 

        def visitXStrNode(node)
          puts "visitXStrNode"
        end 

        def visitYieldNode(node)
          puts "visitYieldNode"
        end 

        def visitZArrayNode(node)
          puts "visitZArrayNode"
        end 

        def visitZSuperNode(node)
          puts "visitZSuperNode"
        end
      end
    end
  end
end
