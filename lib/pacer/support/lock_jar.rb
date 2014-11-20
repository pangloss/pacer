module LockJar
  # If Bundler constant is defined, assume we are running in a bundled environment and
  # register all Jarfiles
  def self.register_bundled_jarfiles
    if defined? Bundler
      Gem::Specification.
        map { |s| File.join(s.full_gem_path, 'Jarfile') }.
        select { |f| File.exists? f }.
        each { |f| LockJar.register_jarfile f }

      # Disable LockJar so that other libraries can't bring in random other jars.
      # TODO: add LockJar.disable! or something like that.
      module ::LockJar
        class << self
          alias orig_lock lock
          alias orig_load load
        end
        def self.lock(*a); end
        def self.load(*a); end
      end
    end
  end
end
