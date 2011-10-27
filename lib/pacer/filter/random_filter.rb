module Pacer
  module Core
    module Route
      # Return elements based on a bias:1 chance.
      #
      # If given an integer (n) > 0, bias is calcualated at 1 / n.
      def random(bias = 0.5)
        bias = 1 / bias.to_f if bias.is_a? Fixnum and bias > 0
        chain_route :pipe_class => Pacer::Pipes::RandomFilterPipe, :pipe_args => bias
      end
    end
  end
end
