module Pacer
  class EnumerablePipe < AbstractPipe
    def initialize(enumerable)
      super()
      case enumerable
      when Enumerable::Enumerator
        @enumerable = enumerable
      when Enumerable
        @enumerable = enumerable.to_enum
      else
        @enumerable = [enumerable].to_enum
      end
    end

    def processNextStart()
      @enumerable.next
    rescue
      raise NoSuchElementException.new
    end
  end
end
