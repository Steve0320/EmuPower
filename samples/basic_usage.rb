require 'emu_power'

# Create initial object. The argument is the path to the TTY
# serial device. This should be replaced with the appropriate
# device for your system (most likely /dev/ttyACM0 or similar).
api = EmuPower::Api.new("/dev/ttyEmu")

# Print demand when receiving demand notification
api.callback(EmuPower::Types::InstantaneousDemand) do |o|
	if o.demand.nil?
		puts "UNKNOWN DEMAND"
	else
		puts "DEMAND WAS #{o.demand} AT #{Time.at(o.timestamp)} (#{o.digits_right})"
	end
end

# Sample global callback
# api.callback(:global) do |o|
# 	puts "GLOBAL CALLBACK #{o.raw}"
# end

# Sample command. Should be sent via api.issue_command(r)
# after start_serial is called in nonblocking mode.
# r = Commands::GetNetworkInfo.new

# Start serial connection. By default, this blocks until
# the inner thread completes. In this case, it will block
# indefinitely until the program is terminated.
api.start_serial
