module Pacer::Pipes
  class VariableStoreIteratorWrapper < AbstractPipe

    field_reader :starts
    attr_accessor :vars

    def initialize(pipe, vars, variable_name)
      super()
      setStarts pipe if pipe
      @vars = vars
      @variable_name = variable_name
    end

    protected

    def processNextStart
      @vars[@variable_name] = starts.next
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
