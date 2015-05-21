require 'yaml'

module Pacer
  # This encoder was originally part of pacer-neo4j. It uses native data where
  # Neo4j could and for everything else it uses (slow (but easy))
  # human-readable YAML encoding.
  class YamlEncoder

import com.xnlogic.pacer.encoder.SimplePropertyEncoder

    def self.encode_property(value)
      case value
      when Fixnum, Float
        value
      when String
        value = value.strip
          value == '' ? nil : value
      when true, false, nil
        value
      when DateTime
        value.new_offset(0).strftime ' utcT %Y-%m-%d %H:%M:%S.%L' 
      when Date
        value.strftime ' date %Y-%m-%d'
        else
          begin     
              SimplePropertyEncoder.encodeProperty(value)
          rescue Exception => ex
              dump(value)
          end
        end
    end


    def self.decode_property(value)
      begin
        decoded_value = SimplePropertyEncoder.decodeProperty(value)
        if decoded_value.nil?
          return nil
        elsif decoded_value.class == Java::JavaUtil::Date
          Time.at(decoded_value.getTime/1000.0)
        else
          convert_to_ruby_array_if_necessary(decoded_value)
        end
      rescue Exception => ex
        if value.start_with? " utcT "
          return DateTime.parse(value[6..-1])
        elsif value.start_with? " date "
          return Date.parse(value[6..-1])
        else
          return YAML.load(value[1..-1]) 
        end
      end
    end


    private

    def self.dump(value)
      " #{ YAML.dump value }"
    end


    def self.convert_to_ruby_array_if_necessary(value)
      if value.respond_to? :to_a
        value = value.to_a
        value.each_index {|i| value[i] = convert_to_ruby_array_if_necessary(value[i])}
      end
      value
    end

  end
end
