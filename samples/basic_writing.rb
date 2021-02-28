# This sample demonstrates sending commands to the EMU. In this sample,
# we close the billing period in response to a SIGUSR1 signal. To use
# this, start the program using `ruby basic_writing.rb`, and in a
# different window run `pgrep ruby` to get the process ID of the
# running program. Run `kill -USR1 <process ID>` to issue the command.

require 'emu_power'

# Create initial object. The argument is the path to the TTY
# serial device. This should be replaced with the appropriate
# device for your system (most likely /dev/ttyACM0 or similar).
api = EmuPower::Api.new("/dev/tty.usbmodem146101")

# Print out a summary on receipt of a usage notification
api.callback(EmuPower::Notifications::CurrentPeriodUsage) do |o|
	puts "Current period [#{Time.at(o.start_date)}]: #{o.current_usage}"
end

# Issue a command on response to a signal
Signal.trap('USR1') do

	puts "Rolling over period and fetching usage"

	# Display the old period
	api.issue_command(EmuPower::Commands::GetCurrentPeriodUsage.new)

	# Close out the period
	api.issue_command(EmuPower::Commands::CloseCurrentPeriod.new)

	# Show usage again to see the difference
	api.issue_command(EmuPower::Commands::GetCurrentPeriodUsage.new)

end

puts "Beginning communication"
api.start_serial