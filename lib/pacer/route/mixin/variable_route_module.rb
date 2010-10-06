module Pacer::Routes
  module VariableRouteModule
    def initialize(back, variable_name)
      @back = back
      @variable_name = variable_name
    end

    def root?
      false
    end

    protected

    def iterator(*args)
      super do |pipe|
        Pacer::Pipes::VariableStoreIteratorWrapper.new(pipe, vars, @variable_name)
      end
    end

    def has_routable_class?
      false
    end

    def inspect_class_name
      @variable_name.inspect
    end
  end
end
