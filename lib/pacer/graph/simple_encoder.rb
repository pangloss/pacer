module Pacer
  class SimpleEncoder
    JBoolean = java.lang.Boolean
    JDate = java.util.Date
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
      elsif value.is_a? JDate
        Time.at value.getTime() / 1000.0
      else
        value
      end
    end
  end
end
