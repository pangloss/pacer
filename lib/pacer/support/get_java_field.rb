module Pacer::Support
  module GetJavaField
    protected

    def get_java_field(name)
      field = self.class.superclass.java_class.declared_field name
      field.accessible = true
      field.value Java.ruby_to_java(self)
    end

    def set_java_field(name, value)
      field = self.class.superclass.java_class.declared_field name
      field.accessible = true
      field.set Java.ruby_to_java(self), value
    end
  end
end
