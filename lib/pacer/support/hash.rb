class Hash
  def to_hash_map
    hm = java.util.HashMap.new
    if block_given?
      each do |key, value|
        hm.put(*yield(key, value))
      end
    else
      each do |key, value|
        hm.put key, value
      end
    end
    hm
  end
end
