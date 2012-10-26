module Pacer
  module Core::SideEffect
    def cap
      back.chain_route :transform => :cap, :with => self, :element_type => :object
    end
  end

  module Transform
    module Cap
      import com.tinkerpop.pipes.transform.SideEffectCapPipe

      def help(section = nil)
        case section
        when nil
          puts <<HELP
Cap executes the full pipeline until it is empty, discarding all of the
pipeline's results. It then calls getSideEffect from the previous pipe
segment and emits that value as the only resulting value of the route.

The value of getSideEffect is generally calculated by processing each
element of the route. A good example is #count which is actually
implemented as follows:

  r = g.v.counted.cap     #=> #<GraphV -> Obj-Cap(V-Counted)>
  r.to_a                  #=> [123]

In this example, #counted is a side effect pipe. Side effect pipes can
be used on their own but their value is not reliable until the full
pipeline has been processed:

  pipe = g.v.counted.pipe
  pipe.getSideEffect      #=> 0
  pipe.next               #=> #<V[3]>
  pipe.getSideEffect      #=> 1

HELP
        else
          super
        end
        description
      end

      def with=(route)
        @side_effect = route
      end

      protected

      def pipe_source
        s, e = super
        if not s and not e
          s = e = Pacer::Pipes::IdentityPipe.new
        end
        [s, e]
      end

      def side_effect_pipe(end_pipe)
        old_back = @side_effect.back
        begin
          empty = Pacer::Route.empty self
          @side_effect.back = empty
          _, side_effect_pipe = @side_effect.send :build_pipeline
          side_effect_pipe.setStarts end_pipe if end_pipe
          side_effect_pipe
        ensure
          @side_effect.back = old_back
        end
      end

      def attach_pipe(end_pipe)
        pipe = SideEffectCapPipe.new side_effect_pipe(end_pipe)
        pipe.setStarts end_pipe if end_pipe
        pipe
      end

      def inspect_string
        "#{ inspect_class_name }(#{ @side_effect.send(:inspect_string) })"
      end
    end
  end
end
