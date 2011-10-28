require 'lib/pacer'

require 'jruby/profiler'

g = Pacer.tg 'samples/grateful-dead.xml'
g.v.out.in.count

profile_data = JRuby::Profiler.profile do
  100.times do
    g.v(type: 'song').out(type: 'artist', name: nil).out_e.in_v.count
  end
end

profile_printer = JRuby::Profiler::GraphProfilePrinter.new(profile_data)
profile_printer.printProfile(STDOUT)
