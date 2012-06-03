require 'pacer/filter/where_filter/node_visitor'

module Pacer
  module Routes
    module RouteOperations
      def where(str, values = {}, *more, &block)
        if str.is_a? String or str.is_a? Symbol
          if str !~ /\A\s*\Z/
            chain_route :filter => :where, :where_statement => str.to_s, :values => values
          else
            self
          end
        else
          filter(str, values, *more, &block)
        end
      end

      def unless(str, values = {})
        if str and str !~ /\A\s*\Z/
          where "not (#{str})", values
        else
          self
        end
      end
    end
  end

  module Filter
    module WhereFilter
      attr_reader :where_statement
      attr_accessor :values

      def where_statement=(str)
        @where_statement = str
        @built = @parsed = @intermediate = nil
      end

      def parsed
        @parsed ||= JRuby.parse @where_statement
      end

      def intermediate
        encoded_values = {}
        if values
          values.each { |k, v| encoded_values[k.to_sym] = graph.encode_property(v) }
        end
        @intermediate ||= parsed.accept(NodeVisitor.new(self, encoded_values))
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
