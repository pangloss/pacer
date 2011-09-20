class NativeException
  def unravel
    e = self
    while e and e.respond_to? :cause
      puts '--------------------'
      puts e.class.to_s
      puts e.message
      pp e.backtrace.to_a
      e = e.cause
    end
    puts '======================'
  end

  def root_cause
    rc = e = self
    while e and e.respond_to? :cause
      rc = e
      e = e.cause
    end
    rc
  end
end
