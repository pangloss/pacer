module Pacer::Pipes
  class PropertyComparisonFilterPipe < RubyPipe
    def initialize(left, right, filter)
      super()
      @filter = filter
      @left = left.to_s
      @right = right.to_s
    end

    protected

    def processNextStart
      while true
        obj = @starts.next
        l = obj.getProperty(@left)
        r = obj.getProperty(@right)
        case @filter
        when FilterPipe::Filter::EQUAL
          return obj if l == r
        when FilterPipe::Filter::NOT_EQUAL
          return obj if l != r
        when FilterPipe::Filter::GREATER_THAN
          return obj if l and r and l > r
        when FilterPipe::Filter::LESS_THAN
          return obj if l and r and l < r
        when FilterPipe::Filter::GREATER_THAN_EQUAL
          return obj if l and r and l >= r
        when FilterPipe::Filter::LESS_THAN_EQUAL
          return obj if l and r and l <= r
        end
      end
    end
  end
end
