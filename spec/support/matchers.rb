module RSpec
  module Core
    module Matchers
      def fail
        raise_error(::RSpec::Expectations::ExpectationNotMetError)
      end

      def fail_with(message)
        raise_error(::RSpec::Expectations::ExpectationNotMetError, message)
      end
    end
  end
end

RSpec::Matchers.define :be_one_of do |*list|
  match do |item|
    list.include? item or list.select { |i| i.is_a? Regexp }.any? { |r| item =~ r }
  end
end
