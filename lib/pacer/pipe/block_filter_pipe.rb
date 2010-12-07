module Pacer::Pipes
  class BlockFilterPipe < RubyPipe
    def initialize(starts, back, block)
      super()
      set_starts(starts)
      @back = back
      @block = block

      @extensions = @back.extensions
      @extension = package_extensions @back, @back.extensions
    end

    def package_extensions(route, extensions)
      extension = Module.new
      extensions.each do |mod|
        extension.send :include, mod::Route if mod.const_defined? :Route
        if route.is_a? Pacer::Routes::VerticesRouteModule
          extension.send(:include, mod::Vertex) if mod.const_defined? :Vertex
        elsif route.is_a? Pacer::Routes::EdgeRouteModule
          extension.send(:include, mod::Edge) if mod.const_defined? :Edge
        end
      end
      extension
    end

    def processNextStart()
      while s = @starts.next
        s.extend Pacer::Routes::SingleRoute
        s.back = @back
        s.extensions.replace @extensions
        s.extend @extension
        ok = @block.call s
        return s if ok
      end
      raise Pacer::NoSuchElementException.new
    end
  end
end
