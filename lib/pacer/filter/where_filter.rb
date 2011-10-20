require 'pacer/filter/where_filter/node_visitor'

module Pacer
  module Routes
    module RouteOperations
      def where(str, vars = {})
        chain_route :filter => :where, :where_statement => str, :vars => vars
      end
    end
  end

  module Filter
    module WhereFilter
      attr_reader :where_statement
      attr_accessor :vars

      def where_statement=(str)
        @where_statement = str
        @built = @parsed = @intermediate = nil
      end

      def parsed
        @parsed ||= JRuby.parse @where_statement
      end

      def intermediate
        @intermediate ||= parsed.accept(NodeVisitor)
      end

      def build!
        @built ||= intermediate.build
      end

      protected

      def attach_pipe(end_pipe)
        pipe = build!
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        "where(#@where_statement)"
      end
    end
  end
end
