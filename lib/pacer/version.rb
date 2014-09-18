module Pacer
  unless const_defined? :VERSION
    VERSION = "1.5.2"

    JAR = "pacer-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"

    START_TIME = Time.now

    BLUEPRINTS_VERSION = "2.6.0-SNAPSHOT"
    PIPES_VERSION = "2.5.0"
  end
end
