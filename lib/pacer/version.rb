module Pacer
  VERSION = "2.0.3"
  unless const_defined? :START_TIME
    START_TIME = Time.now
  end
end
