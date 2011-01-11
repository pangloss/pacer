module Pacer::Routes
  module IndexedRouteModule
    def initialize(index, key, value)
      @index = index
      @key = key
      @value = value
      initialize_path(proc { r = index.get(key, value); r ? r.iterator : [] })
    end

    def count
      if @index and @key and @value
        if @index.respond_to? :count
          @index.count(@key, @value)
        else
          super
        end
      else
        super
      end
    end
  end
end
