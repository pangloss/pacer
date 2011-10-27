module Pacer
  module Filter
    module IndexFilter
      attr_accessor :index, :key, :value

      def count
        if @index and @key and @value
          if @index.respond_to? :count
            @index.count(@key, graph.encode_property(@value))
          else
            super
          end
        else
          super
        end
      end

      protected

      def source_iterator
        src = index.get(key, graph.encode_property(value)) || java.util.ArrayList.new
        src.iterator
      end

      def inspect_string
        "#{ inspect_class_name }(#{ key }: #{value.inspect})"
      end
    end
  end
end
