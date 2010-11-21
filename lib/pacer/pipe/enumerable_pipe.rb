module Pacer::Pipes
  class EnumerablePipe < RubyPipe
    def initialize(enumerable)
      super()
      case enumerable
      when Enumerable::Enumerator
        starts = enumerable
      when Pacer::ElementMixin
        starts = [enumerable].to_enum
      when Enumerable
        starts = enumerable.to_enum
      else
        starts = [enumerable].to_enum
      end
      set_starts starts
    end

    def processNextStart()
      @starts.next
    rescue
      raise Pacer::NoSuchElementException.new
    end
  end
end
