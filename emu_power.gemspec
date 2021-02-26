Gem::Specification.new do |s|
	s.name        = 'emu_power'
	s.version     = '1.2'
	s.summary     = "API for interfacing with the Rainforest EMU energy monitor."
	s.description = "This is an implementation of the XML API for the Rainforest EMU in ruby."
	s.homepage    = "https://github.com/Steve0320/EmuPower"
	s.authors     = ["Steven Bertolucci"]
	s.email       = 'srbertol@mtu.edu'
	s.files       = ["readme.md", "lib/emu_power.rb", "lib/emu_power/api.rb", "lib/emu_power/commands.rb", "lib/emu_power/types.rb", "lib/emu_power/stream_parser.rb"]
	s.license     = 'MIT'
	s.add_runtime_dependency('nokogiri', '~> 1.11')
	s.add_runtime_dependency('serialport', '~> 1.3')
end
