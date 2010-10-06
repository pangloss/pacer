module Pacer::Pipes
  class VariableStoreIteratorWrapper
    def initialize(pipe, vars, variable_name)
      @pipe = pipe
      @vars = vars
      @variable_name = variable_name
    end

    def next
      @vars[@variable_name] = @pipe.next
    end
  end
end
