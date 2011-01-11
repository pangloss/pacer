module Pacer::Routes
  module IndexedRouteModule
    def initialize(index, key, value)
      @index = index
      @key = key
      @value = value
      initialize_path(proc { r = index.get(key, value); r ? r.iterator : [] })
    end

    def count
      if @index and @key and @value and
        if @index.respond_to? :count
          @index.count(@key, @value)
        else
          puts "Use pangloss/blueprints for fast index counts"
          super
        end
      else
        super
      end
    end
  end
end
