# This sample illustrates the usage of the API in its most
# basic form. It registers a listener for showing each
# instantaneous demand notification and then starts communication.

require 'emu_power'

# Create initial object. The argument is the path to the TTY
# serial device. This should be replaced with the appropriate
# device for your system (most likely /dev/ttyACM0 or similar).
api = EmuPower::Api.new("/dev/ttyEmu")

# Print demand when receiving demand notification
api.callback(EmuPower::Notifications::InstantaneousDemand) do |o|
	if o.demand.nil?
		puts "UNKNOWN DEMAND"
	else
		puts "DEMAND WAS #{o.demand} AT #{Time.at(o.timestamp)}"
	end
end

# Start serial connection. By default, this blocks until
# the inner thread completes. In this case, it will block
# indefinitely until the program is terminated.
api.start_serial
