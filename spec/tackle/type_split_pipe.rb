module Tackle
  import com.tinkerpop.pipes.branch.CopySplitPipe

  class TypeSplitPipe < CopySplitPipe
    field_reader :pipes
    field_reader :pipeStarts

    def processNextStart
      while true
        element = starts.next
        case element[:type]
        when 'person'
          return element
        when 'project'
          pipeStarts[0].add(element)
        else
          pipeStarts[1].add(element)
        end
      end
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
