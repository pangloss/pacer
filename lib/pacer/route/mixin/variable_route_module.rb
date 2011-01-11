module Pacer::Routes

  # Adds support to a route to store a variable inline during processing. See
  # Pacer::Routes::RouteOperations#as
  module VariableRouteModule
    attr_accessor :variable_name

    def root?
      false
    end

    protected

    def attach_pipe(pipe)
      Pacer::Pipes::VariableStoreIteratorWrapper.new(pipe, vars, @variable_name)
    end

    def has_routable_class?
      false
    end

    def inspect_class_name
      @variable_name.inspect
    end
  end
end
