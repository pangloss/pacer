module LockJar
  # If Bundler constant is defined, assume we are running in a bundled environment and
  # register all Jarfiles
  def self.register_bundled_jarfiles
    if defined? Bundler
      Gem::Specification.
        map { |s| File.join(s.full_gem_path, 'Jarfile') }.
        select { |f| File.exists? f }.
        each { |f| LockJar.register_jarfile f }
      true
    end
  end
end
