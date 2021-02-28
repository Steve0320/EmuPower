# Collection of command types for controlling various functions on the EMU
# device. These should be constructed and passed as arguments to the API
# object's issue_command method.

class EmuPower::Commands

	# Base class that all commands inherit from
	class Command

		def initialize(name)
			@data = { name: name }
		end

		def to_command

			tags = @data.map do |k, v|
				tag = k.to_s.capitalize
				next "<#{tag}>#{v}</#{tag}>"
			end

			return "<Command>#{tags.join}</Command>"
		end

		# Convert bool to Y or N
		def to_yn(bool)
			return bool ? 'Y' : 'N'
		end

		# Convert int to 0xABCD hex
		def to_hex(i, width = 8)
			return "0x%0#{width}x" % i
		end

	end

	# Helper class for defining basic commands easily. Uses the current class
	# name to define the Command Name element of the output XML.
	class BasicCommand < Command
		def initialize

			class_name = self.class.name.split('::').last
			command_name = class_name
												 .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
												 .gsub(/([a-z\d])([A-Z])/,'\1_\2')
												 .tr("-", "_")
												 .downcase
			super(command_name)

		end
	end


	# Restart the EMU device.
	class Restart < BasicCommand
	end

	# Get the current time. Triggers a TimeCluster notification.
	class GetTime < BasicCommand
	end

	# Get current messages from the device. Triggers a MessageCluster
	# notification for each message.
	class GetMessage < BasicCommand
	end

	# Request information about the meter network. Triggers a
	# NetworkInfo notification.
	class GetNetworkInfo < BasicCommand
	end

	# Request information about the connection between the EMU-2
	# and the meter. Triggers a ConnectionStatus notification.
	class GetConnectionStatus < BasicCommand
	end

	# Request a list of all connected meters. This triggers one
	# MeterList notification for each connected meter.
	class GetMeterList < BasicCommand
	end

	# Get detailed info on a specific meter. If more than one
	# meter is connected, a MAC must be passed to identify
	# the target. Triggers a MeterInfo notification.
	# TODO: Allow passing meter MAC argument
	class GetMeterInfo < BasicCommand
	end

	# Request information about the EMU-2 device. Triggers a
	# DeviceInfo notification.
	class GetDeviceInfo < BasicCommand
	end

	# Get the current fast poll period. Triggers a FastPollStatus
	# notification.
	class GetFastPollStatus < BasicCommand
	end

	# Get a list of the previous billing periods. Triggers a TODO
	class GetBillingPeriods < BasicCommand
	end

	# Get the running total since the last CloseCurrentPeriod
	# command was issued. Triggers a CurrentPeriodUsage notify
	class GetCurrentPeriodUsage < BasicCommand
	end

	# Close out the current billing period. Does not trigger
	# any notifications.
	class CloseCurrentPeriod < BasicCommand
	end

	# Get the previous billing period's usage. Triggers a TODO
	class GetLastPeriodUsage < BasicCommand
	end

	# Get the current power draw in kilowatts. Triggers an
	# InstantaneousDemand notification.
	class GetInstantaneousDemand < BasicCommand
	end

	# Get the current meter reading. This is independent of the
	# current period usage.
	class GetCurrentSummationDelivered < BasicCommand
	end

	# Get the current electricity rate. This is either provided
	# by the meter, or set manually on the device during setup.
	# This triggers a PriceCluster notification.
	class GetCurrentPrice < BasicCommand
	end

	# Get the current block prices. This triggers a BlockPriceDetail
	# notification, and is only applicable to block-based billing
	# schemes.
	class GetPriceBlocks < BasicCommand
	end

	# Set the notification schedule on the EMU. Note: this only seems to be effective shortly after the
	# unit starts up, while the modes of the schedule are all 'default'. After that, the meter seems to
	# push a schedule configuration and set the mode to 'rest', which overwrites the existing schedule
	# and ignores subsequent SetSchedule commands.
	class SetSchedule < Command

		EVENTS = %w[time message price summation demand scheduled_prices profile_data billing_period block_period]

		def initialize(event, frequency, enabled)
			super('set_schedule')
			raise ArgumentError.new("Event must be one of #{EVENTS.join(', ')}") unless EVENTS.include?(event)
			@data[:event] = event
			@data[:frequency] = to_hex(frequency, 4)
			@data[:enabled] = to_yn(enabled)
		end

	end

	# Get the current event schedule. This triggers one ScheduleInfo notification for
	# each of the listed event types.
	class GetSchedule < Command

		EVENTS = %w[time message price summation demand scheduled_prices profile_data billing_period block_period]

		def initialize(event = nil)

			super('get_schedule')

			unless event.nil?
				raise ArgumentError.new("Event must be one of #{EVENTS.join(', ')}") unless EVENTS.include?(event)
				@data[:event] = event
			end

		end

	end

end
