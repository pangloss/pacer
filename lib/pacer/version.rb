module Pacer
  unless const_defined? :VERSION
    VERSION = "0.8.1"

    JAR = "pacer-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"

    START_TIME = Time.now
  end
end
