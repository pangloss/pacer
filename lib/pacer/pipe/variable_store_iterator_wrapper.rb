module Pacer::Pipes
  class VariableStoreIteratorWrapper
    attr_accessor :vars

    def initialize(pipe, vars, variable_name)
      @pipe = pipe
      @vars = vars
      @variable_name = variable_name
    end

    def next
      @vars[@variable_name] = @pipe.next
    end

    def enablePath
      puts 'vs enable path!'
      @pipe.enablePath
    end
    alias enable_path enablePath

    def path
      @pipe.path
    end
  end
end
