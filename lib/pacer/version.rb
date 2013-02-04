module Pacer
  unless const_defined? :VERSION
    VERSION = "1.2.0"

    JAR = "pacer-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"

    START_TIME = Time.now

    BLUEPRINTS_VERSION = "2.2.0"
    PIPES_VERSION = "2.2.0"
    GREMLIN_VERSION = "2.2.0"
  end
end
