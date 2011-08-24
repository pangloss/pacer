module Pacer
  unless const_defined? :VERSION
    VERSION = "0.8.3"

    JAR = "pacer-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"

    START_TIME = Time.now

    BLUEPRINTS_VERSION = "1.0-SNAPSHOT"
    PIPES_VERSION = "0.8-SNAPSHOT"
  end
end
