module Pacer::Pipes
  class LabelsFilterPipe < RubyPipe
    attr_accessor :starts

    def set_labels(labels)
      @labels = labels.map { |label| label.to_s.to_java }
    end

    def set_starts(starts)
      @starts = starts
    end

    def processNextStart()
      while edge = @starts.next
        if @labels.include? edge.get_label
          return edge;
        end
      end
      raise Pacer::NoSuchElementException.new
    end
  end
end
