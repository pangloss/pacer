module RSpec
  module Core
    module SharedExampleGroup
      def contexts(ctxts, &block)
        ctxts.each do |name, setup_proc|
          context(*[*name]) do
            instance_eval &setup_proc
            instance_eval &block
          end
        end
      end
    end
  end
end
