module Pacer
  module Routes
    module RouteOperations
      def group(&block)
        chain_route :transform => :group, :grouped_route => block
      end
    end
  end

  module Transform
    module Group
      def grouped_route=(r)
        if r.respond_to? :call
          empty = Pacer::Route.new :filter => :empty, :back => self
          @grouped_route = r.call(empty).route
        else
          @grouped_route = r
        end
      end

      def grouped_route
        @grouped_route
      end

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::GroupPipe.new *grouped_pipes
        pipe.setStarts end_pipe
        pipe
      end

      def grouped_pipes
        pipes = grouped_route.send(:build_pipeline)
        pipes
      end

      def inspect_string
        "#{ inspect_class_name }(#{ grouped_route.route.inspect })"
      end
    end
  end
end
