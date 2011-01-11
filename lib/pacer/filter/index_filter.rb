module Pacer
  module Filter
    module IndexFilter
      def self.triggers
        [:index]
      end

      attr_accessor :index, :key, :value

      def count
        if @index and @key and @value
          if @index.respond_to? :count
            @index.count(@key, @value)
          else
            super
          end
        else
          super
        end
      end

      protected

      def source
        src = index.get(key, value) || java.util.ArrayList.new
        src.iterator
      end
    end
  end
end
