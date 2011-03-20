module Pacer
  module IndexMixin
    def graph=(graph)
      @graph = graph
    end

    def graph
      @graph
    end

    def first(key, value, extensions = nil)
      e = get(key, value).first
      if e and (@graph or extensions)
        e.graph = @graph
        e.add_extensions extensions
      end
      e
    end

    def all(key, value, extensions = nil)
      iter = get(key, value)
      if @graph or extensions
        iter.extend Pacer::Core::Route::IteratorExtensionsMixin
        iter.graph = @graph
        iter.extensions = extensions
      end
      iter
    end
  end
end
