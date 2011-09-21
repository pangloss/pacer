module Pacer
  unless const_defined? :VERSION
    VERSION = "0.8.6"

    JAR = "pacer-#{ VERSION }-standalone.jar"
    JAR_PATH = "lib/#{ JAR }"

    START_TIME = Time.now

    BLUEPRINTS_VERSION = "1.0"
    PIPES_VERSION = "0.8"
  end
end
