module Pacer::Pipes
  class EnumerablePipe < RubyPipe
    def initialize(enumerable)
      super()
      case enumerable
      when Enumerator
        starts = enumerable
      when Pacer::Wrappers::ElementWrapper
        starts = [enumerable.element].to_enum
      when Enumerable
        starts = enumerable.to_enum
      else
        starts = [enumerable].to_enum
      end
      set_starts starts
    end

    def processNextStart()
      @starts.next
    rescue StopIteration
      raise EmptyPipe.instance
    end
  end
end
