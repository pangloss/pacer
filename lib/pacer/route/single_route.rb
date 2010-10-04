module Pacer
  module SingleRoute
    def [](name)
      map do |element|
        element.get_property(name.to_s)
      end.first
    end

    def label
      labels.first
    end

    def id
      ids.first
    end

    def current
      first
    end

    def ==(element)
      current == element or super
    end
  end
end
