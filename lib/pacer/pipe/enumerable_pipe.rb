module Pacer::Pipes
  class EnumerablePipe < AbstractPipe
    def initialize(enumerable)
      super()
      case enumerable
      when Enumerable::Enumerator
        @enumerable = enumerable
      when Pacer::ElementMixin
        @enumerable = [enumerable].to_enum
      when Enumerable
        @enumerable = enumerable.to_enum
      else
        @enumerable = [enumerable].to_enum
      end
    end

    def processNextStart()
      @enumerable.next
    rescue
      raise Pacer::NoSuchElementException.new
    end
  end
end
