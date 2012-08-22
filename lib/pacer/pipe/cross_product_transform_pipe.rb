module Pacer::Pipes
  class CrossProductTransformPipe < UnaryTransformPipe
    attr_reader :branch_b

    def initialize(method, branch_a, branch_b)
      super(method, branch_a)
      if branch_b.is_a? Pipe
        @branch_b = branch_b
        @b = nil
      else
        @b = branch_b
      end
    end

    def processNextStart
      next_pair
      a.send method, b rescue nil if a.respond_to? method
    end

    protected

    attr_accessor :b

    def next_pair
      if branch_b
        begin
          self.b = branch_b.next
        rescue Pacer::EmptyPipe, java.util.NoSuchElementException
          next_a
          branch_b.setStarts SingleIterator.new(element)
          retry
        rescue NativeException => e
          if @first
            next_a
            branch_b.setStarts SingleIterator.new(element)
            retry
          else
            raise e
          end
        end
      else
        next_a
      end
    end
  end
end
