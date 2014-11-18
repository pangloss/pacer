# TODO: Remove when https://github.com/jmhedden/lock_jar/pull/1 is merged.
module LockJar
  # Add a Jarfile to be included when LockJar.lock_registered_jarfiles is called.
  #
  # @param [String] jarfile path to register
  # @return [Array] All registered jarfiles
  def self.register_jarfile( jarfile )
    fail "Jarfile not found: #{ jarfile }" unless File.exists? jarfile
    @@registered_jarfiles ||= []
    @@registered_jarfiles << jarfile
  end

  # Lock the registered Jarfiles and generate a Jarfile.lock.
  #
  # Options and groups are passed through to the LockJar.lock method, but
  # if a jarfile is specified, it will be ignored. Use LockJar.register_jarfile
  # to add dependencies.
  #
  # A block can be passed in, overriding values from the Jarfiles.
  #
  # @return [Hash] Lock data
  def self.lock_registered_jarfiles( *args, &blk )
    jarfiles = @@registered_jarfiles || []
    instances = jarfiles.map do |jarfile|
      LockJar::Domain::JarfileDsl.create jarfile
    end
    combined = instances.reduce do |result, inst|
      LockJar::Domain::DslHelper.merge result, inst
    end
    args = args.reject { |arg| arg.is_a? String }
    lock combined, *args, &blk
  end
end
