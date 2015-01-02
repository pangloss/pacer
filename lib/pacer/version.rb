module Pacer
  VERSION = "2.0.11.pre"
  # Clients may optionally define the following constants in the Pacer namespace:
  # - LOAD_JARS : set to false to manage jar loading in the client. Be sure to load the jars defined in JARFILES.
  # - LOCKJAR_LOCK_OPTS : set some options to be passed to LockJar.lock (ie. :lockfile, :download_artifacts, :local_repo)
  unless const_defined? :START_TIME
    START_TIME = Time.now
  end
end
