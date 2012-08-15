module Pacer
  class SimpleEncoder
    def self.sanitize_properties(props)
      props
    end

    def self.encode_property(value)
      if value.is_a? String
        value = value.strip
        value unless value == ''
      else
        value
      end
    end

    def self.decode_property(value)
      value
    end
  end
end
