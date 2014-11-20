# Disable LockJar so that other libraries can't bring in random other jars.
# TODO: add LockJar.disable! or something like that.
#
# NOTE: this file should only be loaded by #register_bundled_jarfiles after loading is complete.
module LockJar
  class << self
    alias orig_lock lock
    alias orig_load load
  end
  def self.lock(*a); end
  def self.load(*a); end
end

