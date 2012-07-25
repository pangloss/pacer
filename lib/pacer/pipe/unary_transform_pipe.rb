module Pacer::Pipes
  class UnaryTransformPipe < RubyPipe
    import com.tinkerpop.pipes.Pipe
    import com.tinkerpop.pipes.util.iterators.SingleIterator

    attr_reader :branch_a, :method

    def initialize(method, branch_a)
      super()
      if branch_a.is_a? Pipe
        @branch_a = branch_a
        @a = nil
      else
        @a = branch_a
      end
      @first = true
      @method = method
      @element = nil
    end

    def processNextStart
      next_a
      a.send method rescue nil if a.respond_to? method
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end

    protected

    attr_accessor :element, :a

    def next_element
      @first = false
      self.element = starts.next
    end

    def next_a
      if branch_a
        begin
          self.a = branch_a.next
        rescue NativeException => e
          if e.cause.getClass == Pacer::NoSuchElementException.getClass or @first
            next_element
            branch_a.setStarts SingleIterator.new(element) if branch_a
            retry
          else
            raise e
          end
        end
      else
        next_element
      end
    end
  end
end
