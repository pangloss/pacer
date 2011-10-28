module Pacer
  module Core::SideEffect
    def cap
      back.chain_route :transform => :cap, :with => self, :element_type => :object
    end
  end

  module Transform
    module Cap
      import com.tinkerpop.pipes.transform.SideEffectCapPipe

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
          empty = Pacer::Route.new :filter => :empty, :back => self
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
