class Hash
  def to_hash_map
    hm = java.util.HashMap.new
    each do |key, value|
      hm.put key, value
    end
    hm
  end
end
