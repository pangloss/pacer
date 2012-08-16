module Pacer::Pipes
  class BlockFilterPipe < AbstractPipe
    field_reader :starts
    attr_reader :invert, :block, :back, :graph, :wrapper, :is_element

    def initialize(back, block, invert = false)
      super()
      @back = back
      @block = block
      @graph = back.graph
      @invert = invert
      et = back.element_type if back.graph
      # TODO: prepare the wrapper's extensions in advance
      @wrapper = Pacer::Core::Route::WrapperSelector.build et
      @exts = @back.extensions + [Pacer::Extensions::BlockFilterElement]
      @is_element = @graph.element_type?(back.element_type) if @graph
    end

    def processNextStart()
      while element = wrapper.new(starts.next)
        if is_element
          extended_element = element.add_extensions(@exts)
          extended_element.back = back
          extended_element.graph = graph
          ok = block.call extended_element
        else
          ok = block.call element
        end
        ok = !ok if invert
        return element if ok
      end
      raise Pacer::NoSuchElementException
    rescue NativeException => e
      if e.cause.getClass == Pacer::NoSuchElementException.getClass
        raise e.cause
      else
        raise e
      end
    end
  end
end
