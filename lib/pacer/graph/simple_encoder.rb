module Pacer
  class SimpleEncoder
    JBoolean = java.lang.Boolean
    JFalse = false.to_java

    def self.encode_property(value)
      if value.is_a? String
        value = value.strip
        value unless value == ''
      elsif false == value
        JFalse
      else
        value
      end
    end

    def self.decode_property(value)
      if value.is_a? JBoolean and value == JFalse
        false
      else
        value
      end
    end
  end
end
