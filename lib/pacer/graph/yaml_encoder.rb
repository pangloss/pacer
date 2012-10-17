require 'yaml'

module Pacer
  # This encoder was originally part of pacer-neo4j. It uses native data where
  # Neo4j could and for everything else it uses (slow (but easy))
  # human-readable YAML encoding.
  class YamlEncoder
    def self.encode_property(value)
      case value
      when nil
        nil
      when String
        value = value.strip
        value = nil if value == ''
        value
      when Numeric
        if value.is_a? Bignum
          dump value
        else
          value.to_java
        end
      when true, false
        value.to_java
      when Array
        if value.length == 0
          value_type = Fixnum
        else
          value_type = value.first.class
          value_type = TrueClass if value_type == FalseClass
          value.each do |v|
            if value_type != v.class or (value == true or value == false and value_type == TrueClass)
              value_type = nil
              break
            end
          end
        end
        case value_type
        when Fixnum
          value.to_java :long
        when Float
          value.to_java :double
        when TrueClass
          value.to_java :boolean
        when String
          value.to_java :string
        else
          dump value
        end
      else
        dump value
      end
    end

    def self.decode_property(value)
      if value.is_a? String and value[0, 1] == ' '
        YAML.load(value[1..-1])
      elsif value.is_a? ArrayJavaProxy
        value.to_a
      else
        value
      end
    rescue Psych::SyntaxError
      value
    end

    private

    def self.dump(value)
      " #{ YAML.dump value }"
    end
  end
end
