# This sample shows how to use the API in non-blocking mode
# to issue a command. This issues a GET SCHEDULE command,
# and echoes all notify objects.

require 'emu_power'

# Create initial object. The argument is the path to the TTY
# serial device. This should be replaced with the appropriate
# device for your system (most likely /dev/ttyACM0 or similar).
api = EmuPower::Api.new("/dev/ttyEmu")

# Dump all messages received
api.callback(:global) do |o|
	raw = o.raw
	if raw["MessageType"] != "InstantaneousDemand"
		puts raw
	end
end

# Start serial connection. By default, this blocks until
# the inner thread completes. In this case, it will block
# indefinitely until the program is terminated.
api.start_serial(blocking: false)

# Sleep a bit since the EMU sometimes takes bit to start
# responding. This could probably also be solved by issuing
# an initialize command.
sleep(5)

puts "ISSUING GET SCHEDULE COMMAND"
command = EmuPower::Commands::GetSchedule.new
api.issue_command(command)

puts "SLEEPING MAIN THREAD"
sleep
