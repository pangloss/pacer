module Pacer
  unless const_defined? :VERSION
    VERSION = "1.0.0.pre"

    JAR = "pacer-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"

    START_TIME = Time.now

    BLUEPRINTS_VERSION = "2.1.0-SNAPSHOT"
    PIPES_VERSION = "2.1.0-SNAPSHOT"
  end
end
