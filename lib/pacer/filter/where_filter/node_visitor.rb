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

        def pipeline(name, *pipes)
          puts "pipeline"
          if pipes.count > 1
            pipe = Pacer::Pipes::Pipeline.new *pipes
          else
            pipe = pipes.first
          end
          if Pacer.debug_pipes
            if name.is_a? Hash
              Pacer.debug_pipes << name.merge(:pipeline => pipes, :end => pipe)
            else
              Pacer.debug_pipes << { :name => name, :pipeline => pipes, :end => pipe }
            end
          end
          pipe
        end

        def visitAliasNode(node)
          puts "visitAliasNode"
        end 

        def visitAndNode(node)
          a = node.first_node.accept(self)
          b = node.second_node.accept(self)

          #pipeline({ :name => 'and', :and => [a, b], :and_ends => [a, b] }, AndFilterPipe.new(a, b))
          if a.first == :and and b.first == :and
            [:and, *a[1..-1], *b[1..-1]]
          elsif a.first == :and
            [:and, *a[1..-1], b]
          elsif b.first == :and
            [:and, a, *b[1..-1]]
          else
            [:and, a, b]
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
          node.child_nodes.map { |n| n.accept self }
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
          stuff = [node.receiver_node.accept(self), node.name, node.args_node.accept(self).first]
          stuff
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
          puts "visitFalseNode"
        end 

        def visitFCallNode(node)
          puts "visitFCallNode"
        end 

        def visitFixnumNode(node)
          [:value, node.value]
        end 

        def visitFlipNode(node)
          puts "visitFlipNode"
        end 

        def visitFloatNode(node)
          [:value, node.value]
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
          [[:property, node.name], '==', node.value_node.accept(self)]
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
          [:value, nil]
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
          #pipeline({ :name => 'or', :or => [a, b]}, OrFilterPipe.new(a, b))
          if a.first == :or and b.first == :or
            [:or, *a[1..-1], *b[1..-1]]
          elsif a.first == :or
            [:or, *a[1..-1], b]
          elsif b.first == :or
            [:or, a, *b[1..-1]]
          else
            [:or, a, b]
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
          [:value, node.value]
        end 

        def visitSuperNode(node)
          puts "visitSuperNode"
        end 

        def visitSValueNode(node)
          puts "visitSValueNode"
        end 

        def visitSymbolNode(node)
          [:value, node.name]
        end 

        def visitToAryNode(node)
          puts "visitToAryNode"
        end 

        def visitTrueNode(node)
          puts "visitTrueNode"
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
          [:property, node.name]
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
