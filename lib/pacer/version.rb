module Pacer
  VERSION = "2.0.1"
  unless const_defined? :START_TIME
    START_TIME = Time.now
  end
end
