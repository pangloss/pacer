begin
  require 'awesome_print'
rescue LoadError
end

# Fix the way ap indents hashes:

# for awesome_print <= 0.4.0
class AwesomePrint
# for awesome_print >= 1.0.0
#class AwesomePrint::Formatter
  private

  # Format a hash. If @options[:indent] if negative left align hash keys.
  #------------------------------------------------------------------------------
  def awesome_hash(h)
    return "{}" if h == {}

    keys = @options[:sorted_hash_keys] ? h.keys.sort { |a, b| a.to_s <=> b.to_s } : h.keys
    data = keys.map do |key|
      plain_single_line do
        #[ @inspector.awesome(key), h[key] ]
        [ awesome(key), h[key] ]
      end
    end
      
    data = data.map do |key, value|
      if @options[:multiline]
        formatted_key = indent + key
      else
        formatted_key = key
      end
      indented do
        #formatted_key << colorize(" => ", :hash) << @inspector.awesome(value)
        formatted_key << colorize(" => ", :hash) << awesome(value)
      end
    end
    if @options[:multiline]
      "{\n" << data.join(",\n") << "\n#{outdent}}"
    else
      "{ #{data.join(', ')} }"
    end
  end
end
