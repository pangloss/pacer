module Pacer
  class Route
    class << self
      # This method is useful for creating sideline routes that branch
      # off of the current route.
      #
      # It creates a new route without any source based on the type,
      # filters, function and extensions of the given route. The main
      # thing about the returned route is that the pipeline that is
      # built from it will not include any of the pipes that make up
      # the route it's based on.
      #
      # @param [Route] back the route the new route is based on.
      # @return [Route]
      def empty(back)
        back.chain_route :filter => :empty
      end

      def block_branch(back, block, branch_start = nil)
        if block.arity == 0
          route = block.call rescue nil
        else
          unless branch_start
            if back.is_a? Pacer::Graph
              branch_start = back
            else
              branch_start = Pacer::Route.empty(back)
            end
          end
          route = block.call(branch_start) rescue nil
        end
        if route == branch_start
          identity_branch(back).route
        elsif route.is_a? Pacer::Route
          route.route
        else
          empty(back).map(&block).route
        end
      end

      def identity_branch(back)
        Pacer::Route.empty(back).chain_route(:pipe_class => Pacer::Pipes::IdentityPipe,
                                             :route_name => '@').route
      end

    end
  end


  module Filter
    module EmptyFilter
      protected

      def after_initialize
        @back = @source = nil
        super
      end

      def build_pipeline
        nil
      end

      def inspect_class_name
        s = case element_type
            when :vertex
              'V'
            when :edge
              'E'
            when :object
              'Obj'
            when :mixed
              'Elem'
            end
        s = "#{s} #{ @info }" if @info
        s
      end
    end
  end
end
