module Pacer
  module Filter
    module PropertyFilter
      def self.triggers
        [:filters, :block]
      end

      def pipe
        Pacer::Pipes::FutureFilterPipe
      end

      def filters=(filter_array)
        case filter_array
        when Array
          @filters = filter_array
        when nil
          @filters = []
        else
          @filters = [filter_array]
        end
        # Sometimes filters are modules. If they contain a Route submodule, extend this route with that module.
        add_extensions @filters
      end

      def block=(block)
        @block = block
      end
    end
  end
end
