module Pacer::Graph
  class HashIndex
    attr_reader :name, :type

    def initialize(element_type, name)
      @type = type
      @name = name
      @data = Hash.new do |h, k|
        h[k] = Hash.new { |h, k| h[k] = Set[] }
      end
    end

    def get(key, value)
      Pacer::Pipes::EnumerablePipe.new data[key][value]
    end

    def put(key, value, element)
      data[key][value] << element
    end

    def count(key, value)
      data[key][value].count
    end

    private

    attr_reader :data
  end
end
