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
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end

    def enablePath
      @pipe.enablePath
    end
    alias enable_path enablePath

    def path
      @pipe.path
    end
  end
end
